// RuleBasedIntentAnalyzer(IntentAnalyzer의 규칙 기반 구현체)가 CommandParserService의
// 분류 결과를 IntentResult로 올바르게 옮겨 담는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/adapters/rule_based_intent_analyzer.dart';
import 'package:ason_voice_app/features/ason_connect/services/command_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analyzer = RuleBasedIntentAnalyzer(CommandParserService());

  test('일정 키워드가 있으면 schedule로 분류된다', () {
    final result = analyzer.analyze('내일 오후 3시에 팀 회의');

    expect(result.category, DraftCommandCategory.schedule);
    expect(result.isUnclassified, isFalse);
    expect(result.isAmbiguous, isFalse);
  });

  test('건강 키워드/수치가 있으면 health로 분류된다', () {
    final result = analyzer.analyze('오늘 몸무게 72.5kg');

    expect(result.category, DraftCommandCategory.health);
  });

  test('메모 키워드가 있으면 memo로 분류된다', () {
    final result = analyzer.analyze('우유하고 계란 사야 해');

    expect(result.category, DraftCommandCategory.memo);
  });

  test('두 카테고리 점수가 충돌하면 애매한 것으로 표시된다', () {
    final result = analyzer.analyze('아이디어 메모, ASON 음성 앱 개선');

    expect(result.isAmbiguous, isTrue);
    expect(result.alternativeCategory, isNotNull);
  });

  test('아무 신호도 없으면 미분류로 표시된다', () {
    final result = analyzer.analyze('안녕하세요 오늘 날씨가 좋네요');

    expect(result.isUnclassified, isTrue);
  });
}
