// beginSync/beginSyncItem이 내용 없는 카드를 syncing으로 전환하지 않아서,
// MockSyncService와 CoreSyncMapper가 아예 호출되지 않는지 스파이(spy)로
// 직접 확인합니다. (ConversationManager는 두 서비스를 생성자 주입으로 받으므로
// 테스트에서 감시용 하위 클래스를 넣어 실제 호출 여부를 관찰할 수 있습니다)

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:ason_voice_app/features/ason_connect/services/mock_sync_service.dart';
import 'package:ason_voice_app/features/ason_connect/models/sync_payload.dart';
import 'package:ason_voice_app/features/core_sync/services/core_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpyMockSyncService extends MockSyncService {
  bool called = false;

  @override
  Future<SyncResult> sync(SyncPayload payload) async {
    called = true;
    return super.sync(payload);
  }
}

class _SpyCoreSyncMapper extends CoreSyncMapper {
  bool called = false;

  @override
  Future<CoreSyncResult> sync(DraftCommand draft) async {
    called = true;
    return super.sync(draft);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('beginSync: 빈 카드는 syncing으로 전환되지 않는다', () {
    final manager = ConversationManager();
    manager.handleUserText('미팅 있어');
    expect(manager.currentDraft?.hasRequiredContent, isFalse);

    manager.beginSync();

    expect(manager.currentDraft?.status, DraftCommandStatus.ready);
  });

  test('beginSyncItem: 빈 카드는 syncing으로 전환되지 않는다', () {
    final manager = ConversationManager();
    manager.handleUserText('미팅, 매일 아침 스트레칭하기');
    final emptyIndex = manager.items.indexWhere(
      (item) => !item.draft.hasRequiredContent,
    );
    expect(emptyIndex, isNonNegative);

    manager.beginSyncItem(emptyIndex);

    expect(manager.items[emptyIndex].draft.status, DraftCommandStatus.ready);
  });

  test('빈 카드에서는 MockSyncService.sync가 호출되지 않는다', () async {
    final spySync = _SpyMockSyncService();
    final manager = ConversationManager(syncService: spySync);
    manager.handleUserText('미팅 있어');

    manager.beginSync();
    await manager.finishSync();

    expect(spySync.called, isFalse);
  });

  test('빈 카드에서는 CoreSyncMapper.sync가 호출되지 않는다', () async {
    final spyMapper = _SpyCoreSyncMapper();
    final manager = ConversationManager(coreSyncMapper: spyMapper);
    manager.handleUserText('미팅 있어');

    manager.beginSync();
    await manager.finishSync();

    expect(spyMapper.called, isFalse);
  });

  test('유효한 카드에서는 MockSyncService와 CoreSyncMapper가 모두 호출된다', () async {
    final spySync = _SpyMockSyncService();
    final spyMapper = _SpyCoreSyncMapper();
    final manager = ConversationManager(
      syncService: spySync,
      coreSyncMapper: spyMapper,
    );
    manager.handleUserText('내일 오후 3시 영동에서 광고미팅');

    manager.beginSync();
    await manager.finishSync();

    expect(spySync.called, isTrue);
    expect(spyMapper.called, isTrue);
    expect(manager.currentDraft?.status, DraftCommandStatus.synced);
  });

  test('다중 카드: 빈 항목은 beginSyncItem 이후에도 CoreSyncMapper가 호출되지 않는다', () async {
    final spyMapper = _SpyCoreSyncMapper();
    final manager = ConversationManager(coreSyncMapper: spyMapper);
    manager.handleUserText('미팅, 매일 아침 스트레칭하기');

    final emptyIndex = manager.items.indexWhere(
      (item) => !item.draft.hasRequiredContent,
    );
    manager.beginSyncItem(emptyIndex);
    await manager.finishSyncItem(emptyIndex);

    expect(spyMapper.called, isFalse);
  });
}
