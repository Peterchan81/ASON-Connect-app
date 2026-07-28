// 일정 외 카테고리(메모/건강)도 실제 사람과 대화하듯, 꼭 필요한 내용이 빠지면
// 한 가지만 되물은 뒤 저장하는지 검증합니다. (SimpleContinuationHandler)

import 'package:ason_voice_app/features/ason_connect/models/chat_message.dart';
import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_turn_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('메모: "메모가 있어"처럼 내용이 없으면 제목을 먼저 묻고, 답하면 "저장 완료"로 끝난다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '메모가 있어'));
    expect(started.draft?.category, DraftCommandCategory.memo);
    expect(started.draft?.status, DraftCommandStatus.collecting);
    expect(started.messages.single.text, '제목을 입력해주세요.');
    expect(started.messages.single.type, ChatMessageType.question);

    final finished = engine.process(
      BrainInput(text: 'ASON 음성 앱 다국어 지원', draft: started.draft),
    );
    expect(finished.draft?.status, DraftCommandStatus.ready);
    expect(finished.draft?.title, 'ASON 음성 앱 다국어 지원');
    expect(finished.messages.single.text, '저장 완료');
    expect(finished.turnType, BrainTurnType.simpleContinuation);
  });

  test('건강: 수치 없이 "혈압 쟀어"라고 하면 수치를 되묻고, 답하면 저장된다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '오늘 혈압 쟀어'));
    expect(started.draft?.category, DraftCommandCategory.health);
    expect(started.draft?.status, DraftCommandStatus.collecting);
    expect(started.draft?.healthItem, '혈압');
    expect(started.messages.single.text, '혈압 수치를 알려주세요. (예: 128/82)');

    final finished = engine.process(
      BrainInput(text: '128/82', draft: started.draft),
    );
    expect(finished.draft?.status, DraftCommandStatus.ready);
    expect(finished.draft?.title, '128/82');
    expect(finished.messages.single.text, '건강 기록을 저장했습니다.');
  });

  test('건강: "약 먹었어"처럼 이름이 없으면 어떤 약인지 되묻는다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '약 먹었어'));
    expect(started.draft?.status, DraftCommandStatus.collecting);
    expect(started.draft?.healthItem, '복용');
    expect(started.messages.single.text, '어떤 약을 드셨나요?');
  });
}
