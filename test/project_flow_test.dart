// 프로젝트 생성 -> 확인(Summary/Sync 준비) -> 수정(활동/진행률)까지, BrainEngine을
// 통해 실제로 어떻게 흐르는지 검증합니다. 일정/건강/메모와 동일한 BrainEngine
// 파이프라인(NewTopicHandler -> CategoryDraftBuilder -> EditingHandler)을 그대로
// 타는지 확인하는 것이 목적입니다.

import 'package:ason_voice_app/features/ason_connect/models/chat_message.dart';
import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('새 프로젝트는 곧바로 활동(생성) 상태로 Summary/Sync가 준비된다', () {
    final result = BrainEngine().process(
      BrainInput(text: '새 프로젝트 시작: ASON 리브랜딩'),
    );

    expect(result.draft?.category, DraftCommandCategory.project);
    expect(result.draft?.status, DraftCommandStatus.ready);
    expect(result.draft?.title, 'ASON 리브랜딩');
    expect(result.draft?.projectAction, '생성');
    expect(result.summaryReady, isTrue);
    expect(result.syncReady, isTrue);
  });

  test('삭제 표현이 있으면 활동이 "삭제"로 시작된다', () {
    final result = BrainEngine().process(BrainInput(text: 'ASON 리브랜딩 프로젝트 삭제'));

    expect(result.draft?.projectAction, '삭제');
  });

  test('진행률이 포함된 문장은 활동이 "수정"이고 진행률도 함께 저장된다', () {
    final result = BrainEngine().process(
      BrainInput(text: 'ASON 리브랜딩 진행률 60%로 수정'),
    );

    expect(result.draft?.projectAction, '수정');
    expect(result.draft?.progress, '60%');
  });

  test('수정 대화로 활동과 진행률을 각각 자연어로 바꿀 수 있다', () {
    final engine = BrainEngine();

    final created = engine.process(BrainInput(text: '새 프로젝트 시작: ASON 리브랜딩'));
    expect(created.draft?.status, DraftCommandStatus.ready);

    final editingDraft = created.draft!.copyWith(
      status: DraftCommandStatus.editing,
    );
    final progressUpdated = engine.process(
      BrainInput(text: '진행률은 40%', draft: editingDraft),
    );

    expect(progressUpdated.draft?.status, DraftCommandStatus.ready);
    expect(progressUpdated.draft?.progress, '40%');
    expect(progressUpdated.messages.first.text, '진행률을 40%로 변경했습니다.');
    expect(progressUpdated.messages.last.type, ChatMessageType.summary);

    final editingAgain = progressUpdated.draft!.copyWith(
      status: DraftCommandStatus.editing,
    );
    final actionUpdated = engine.process(
      BrainInput(text: '활동은 완료', draft: editingAgain),
    );

    expect(actionUpdated.draft?.projectAction, '완료');
    // 진행률처럼 이전 턴에 바뀐 값은 이번 턴에 다시 지정하지 않아도 유지된다.
    expect(actionUpdated.draft?.progress, '40%');
  });
}
