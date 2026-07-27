// NewTopicHandler가 새 주제 입력(일정/건강/메모)에 대해 올바른 카테고리와 상태로
// draft를 시작하는지 검증합니다. handlers 목록을 NewTopicHandler 하나로 제한해서
// 다른 Handler의 개입 없이 이 Handler만 단위 테스트합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/handlers/new_topic_handler.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = BrainEngine(handlers: const [NewTopicHandler()]);

  test('일정 문장은 schedule 카테고리로 draft를 시작한다', () {
    final result = engine.process(BrainInput(text: '내일 오후 3시에 팀 회의'));

    expect(result.draft?.category, DraftCommandCategory.schedule);
    expect(result.draft?.status, DraftCommandStatus.collecting);
    expect(result.draft?.date, '내일');
    expect(result.draft?.time, '오후 3시');
  });

  test('건강 문장은 곧바로 ready 상태의 draft를 만든다', () {
    final result = engine.process(BrainInput(text: '오늘 몸무게 72.5kg'));

    expect(result.draft?.category, DraftCommandCategory.health);
    expect(result.draft?.status, DraftCommandStatus.ready);
    expect(result.draft?.healthItem, '체중');
  });

  test('메모 문장은 곧바로 ready 상태의 draft를 만든다', () {
    final result = engine.process(BrainInput(text: '우유하고 계란 사야 해'));

    expect(result.draft?.category, DraftCommandCategory.memo);
    expect(result.draft?.status, DraftCommandStatus.ready);
    expect(result.draft?.title, '우유와 계란 구매');
  });
}
