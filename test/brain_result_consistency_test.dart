// BrainResult가 턴 종류와 상관없이 일관된 분석 정보를 유지하는지 검증합니다.
// (activeIntent/accumulatedEntities/changedFields) — 단, 실제 분석이 없었던
// 값(intent/entities)을 거짓으로 만들어 내지 않는지도 함께 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = BrainEngine();

  test('후속 답변 턴에도 activeIntent(현재 카테고리)가 유지된다', () {
    final started = engine.process(BrainInput(text: '내일 오후 3시에 팀 회의'));
    expect(started.draft?.status, DraftCommandStatus.collecting);
    expect(started.activeIntent, DraftCommandCategory.schedule);

    final continued = engine.process(
      BrainInput(text: '30분 전', draft: started.draft),
    );

    // 이번 턴은 새로 분류하지 않았으므로 신선한 intent 분석 결과는 없지만,
    expect(continued.intent, isNull);
    // activeIntent는 지금 draft의 카테고리를 거짓 없이 그대로 보여준다.
    expect(continued.activeIntent, DraftCommandCategory.schedule);
  });

  test('수정 턴에서는 실제로 바뀐 필드만 changedFields로 돌아온다', () {
    final started = engine.process(BrainInput(text: '내일 오후 3시에 김 과장과 미팅'));
    final ready = engine.process(BrainInput(text: '없음', draft: started.draft));
    final editing = ready.draft!.copyWith(status: DraftCommandStatus.editing);

    final corrected = engine.process(
      BrainInput(text: '시간을 오후 4시로 바꿔줘', draft: editing),
    );

    expect(corrected.changedFields, ['time']);
  });

  test('누적 Entity는 이번 턴에 새로 추출하지 않은 필드도 포함한다', () {
    final started = engine.process(BrainInput(text: '내일 오후 3시에 팀 회의'));

    final continued = engine.process(
      BrainInput(text: '30분 전', draft: started.draft),
    );

    // 이번 턴에 새로 추출한 Entity는 없다.
    expect(continued.entities, isNull);
    // 하지만 draft에 이미 누적된 값은 accumulatedEntities로 계속 확인할 수 있다.
    expect(continued.accumulatedEntities?.time, '오후 3시');
    expect(continued.accumulatedEntities?.title, '팀 회의');
    expect(continued.accumulatedEntities?.date, '내일');
  });

  test('분석이 없었던 턴은 entities를 거짓으로 만들어 내지 않는다', () {
    final started = engine.process(BrainInput(text: '내일 오후 3시에 팀 회의'));

    final continued = engine.process(
      BrainInput(text: '30분 전', draft: started.draft),
    );

    expect(continued.entities, isNull);
    expect(continued.intent, isNull);
  });
}
