// 단일 카드(finishSync)와 다중 카드(finishSyncItem)가 공통 경로([_syncDraft])를
// 통해 완전히 같은 정책(유효성 검사 → MockSyncService → CoreSyncMapper)을
// 쓰는지 검증합니다. 내용이 비어 있어도 추가 질문이 생성되지 않고, 카드에
// 정적인 안내 문구만 남는지도 함께 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('단일 카드: 내용이 없으면 되묻지 않고, 동기화만 거부되고 안내 문구가 남는다', () async {
    final manager = ConversationManager();
    manager.handleUserText('미팅 있어');

    final draft = manager.currentDraft!;
    expect(draft.status, DraftCommandStatus.ready);
    expect(draft.hasRequiredContent, isFalse);
    expect(manager.pendingQuestion, isNull);
    expect(manager.messages.any((m) => m.text.contains('내용은 무엇인가요')), isFalse);

    manager.beginSync();
    await manager.finishSync();

    expect(manager.currentDraft?.status, DraftCommandStatus.ready);
    expect(manager.lastSyncError, '내용을 입력하거나 수정해 주세요.');
  });

  test('단일 카드: 내용이 있으면 정상 동기화된다', () async {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시 영동에서 광고미팅');
    expect(manager.currentDraft?.hasRequiredContent, isTrue);

    manager.beginSync();
    await manager.finishSync();

    expect(manager.currentDraft?.status, DraftCommandStatus.synced);
    expect(manager.lastSyncError, isNull);
  });

  test('다중 카드: 내용이 없는 항목은 "모두 동기화"에서도 저장되지 않고 그대로 남는다', () async {
    final manager = ConversationManager();
    manager.handleUserText('미팅, 매일 아침 스트레칭하기');

    expect(manager.items.length, 2);
    final emptyItem = manager.items.firstWhere(
      (item) => item.draft.category == DraftCommandCategory.schedule,
    );
    expect(emptyItem.draft.hasRequiredContent, isFalse);
    // 되묻지 않는다 — 정적 검증 결과만 카드에 남는다.
    expect(emptyItem.pendingQuestion, isNull);

    await manager.syncAllItems();

    // 유효한 항목(나의 하루 목표)만 사라지고, 빈 항목은 실패 이유와 함께 남는다.
    expect(manager.items.length, 1);
    expect(manager.items.single.draft.category, DraftCommandCategory.schedule);
    expect(manager.items.single.syncError, '내용을 입력하거나 수정해 주세요.');
  });

  test('빈 내용이어도 카드는 곧바로 ready 상태로 표시된다(입력 폼처럼 되묻지 않음)', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시');

    final draft = manager.currentDraft!;
    expect(draft.status, DraftCommandStatus.ready);
    expect(draft.title, isNull);
    expect(manager.pendingQuestion, isNull);
  });
}
