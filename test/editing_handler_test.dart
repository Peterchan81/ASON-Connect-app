// EditingHandler가 수정 대화(status == editing)에서 필드를 올바르게 바꾸고
// 다시 ready 상태로 되돌리는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_turn_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = BrainEngine();

  DraftCommand readyScheduleDraft() {
    final started = engine.process(BrainInput(text: '내일 오후 3시에 김 과장과 미팅'));
    final afterAlarm = engine.process(
      BrainInput(text: '없음', draft: started.draft),
    );
    expect(afterAlarm.draft?.status, DraftCommandStatus.ready);
    return afterAlarm.draft!;
  }

  test('시간 수정: "시간을 오후 4시로 바꿔줘"는 time만 바꾸고 다시 ready가 된다', () {
    final editing = readyScheduleDraft().copyWith(
      status: DraftCommandStatus.editing,
    );

    final corrected = engine.process(
      BrainInput(text: '시간을 오후 4시로 바꿔줘', draft: editing),
    );

    expect(corrected.draft?.time, '오후 4시');
    expect(corrected.draft?.status, DraftCommandStatus.ready);
    expect(corrected.changedFields, ['time']);
    expect(corrected.turnType, BrainTurnType.editing);
    expect(corrected.messages.length, 2);
  });

  test('알림 수정: "알림은 30분 전"은 alarm만 바꾼다', () {
    final editing = readyScheduleDraft().copyWith(
      status: DraftCommandStatus.editing,
    );

    final corrected = engine.process(
      BrainInput(text: '알림은 30분 전', draft: editing),
    );

    expect(corrected.draft?.alarm, '30분 전');
    expect(corrected.draft?.status, DraftCommandStatus.ready);
    expect(corrected.changedFields, ['alarm']);
  });

  test('해석할 수 없는 수정 문장은 다시 물어보고 draft를 바꾸지 않는다', () {
    final editing = readyScheduleDraft().copyWith(
      status: DraftCommandStatus.editing,
    );

    final result = engine.process(BrainInput(text: '음...', draft: editing));

    expect(result.draft?.status, DraftCommandStatus.editing);
    expect(result.changedFields, isEmpty);
    expect(result.messages.single.text, '어떤 항목을 어떻게 바꿀지 다시 말씀해 주세요.');
  });
}
