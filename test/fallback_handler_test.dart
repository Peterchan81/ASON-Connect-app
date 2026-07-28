// FallbackHandler(빈 입력 전용)와, "미분류 입력이 최종적으로 fallback 결과로
// 정리되는지"를 검증합니다.
//
// 미분류 판정은 분류를 실제로 시도해 봐야만 알 수 있어서, canHandle만으로 미리
// 판단할 수 없습니다. 그래서 FallbackHandler.canHandle은 빈 입력만 처리하고,
// 미분류 결과는 NewTopicHandler가 BrainResultComposer.unclassified()를 통해
// fallback으로 태그된 BrainResult를 돌려줍니다. 아래 두 번째 테스트는 그 최종
// 결과(turnType)를 기본 BrainEngine(전체 Handler 포함)으로 확인합니다.

import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/handlers/fallback_handler.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_turn_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FallbackHandler는 빈 입력을 draft 변경 없이 정리한다', () {
    final engine = BrainEngine(handlers: const [FallbackHandler()]);

    final result = engine.process(BrainInput(text: '   '));

    expect(result.messages, isEmpty);
    expect(result.draft, isNull);
    expect(result.turnType, BrainTurnType.fallback);
  });

  test('미분류 입력은 결과적으로 fallback으로 정리된다', () {
    final engine = BrainEngine(); // 전체 Handler 포함 (NewTopicHandler가 분류를 시도)

    final result = engine.process(BrainInput(text: '안녕하세요 오늘 날씨가 좋네요'));

    expect(result.draft, isNull);
    expect(result.isUncertain, isTrue);
    expect(result.turnType, BrainTurnType.fallback);
  });
}
