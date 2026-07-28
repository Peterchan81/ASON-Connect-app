// ScheduleContinuationHandler가 일정 수집 중(status == collecting)의 후속 답변을
// 올바르게 반영하는지 검증합니다. (배치 질문 답변 / 장소 재확인 응답)

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_turn_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('시간/알림 배치 질문에 답하면 두 필드가 함께 채워지고 ready가 된다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '내일 둔산동에서 김 과장과 미팅'));
    expect(started.draft?.status, DraftCommandStatus.collecting);
    expect(started.missingFields, containsAll(['time', 'alarm']));

    final continued = engine.process(
      BrainInput(text: '오후 5시\n30분 전', draft: started.draft),
    );

    expect(continued.draft?.time, '오후 5시');
    expect(continued.draft?.alarm, '30분 전');
    expect(continued.draft?.status, DraftCommandStatus.ready);
    expect(continued.turnType, BrainTurnType.scheduleContinuation);
    expect(continued.changedFields, containsAll(['time', 'alarm']));
  });

  test('불확실한 장소를 확인("네")하면 location이 채워진다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '둔산에서 미팅'));
    expect(started.draft?.pendingLocationGuess, '대전 둔산동');
    expect(started.draft?.location, isNull);

    final confirmed = engine.process(
      BrainInput(text: '네', draft: started.draft),
    );

    expect(confirmed.draft?.location, '대전 둔산동');
    expect(confirmed.draft?.pendingLocationGuess, isNull);
    expect(confirmed.changedFields, contains('location'));
    expect(confirmed.turnType, BrainTurnType.scheduleContinuation);
  });

  test('불확실한 장소를 거절("아니요")하면 다시 물어본다', () {
    final engine = BrainEngine();

    final started = engine.process(BrainInput(text: '둔산에서 미팅'));
    final rejected = engine.process(
      BrainInput(text: '아니요', draft: started.draft),
    );

    expect(rejected.draft?.location, isNull);
    expect(rejected.draft?.pendingLocationGuess, isNull);
    expect(rejected.messages.single.text, '장소를 다시 알려주세요.');
  });
}
