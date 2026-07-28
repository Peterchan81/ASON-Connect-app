// "ASON에 동기화" 버튼을 눌렀을 때(beginSync/finishSync) 실제로 ASON-Core와 같은
// 구조로 로컬에 저장되는지 검증합니다. UI 흐름(메시지/상태 전이)은 기존 그대로
// 유지되어야 하므로 함께 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/chat_message.dart';
import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:ason_voice_app/features/core_sync/services/memo_core_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('메모를 완성해 동기화하면 ASON-Core 구조(MemoCoreRepository)에 실제로 저장된다', () async {
    final manager = ConversationManager();

    manager.handleUserText('메모가 있어');
    manager.handleUserText('ASON 음성 앱 다국어 지원');
    expect(manager.currentDraft?.status, DraftCommandStatus.ready);

    manager.beginSync();
    expect(manager.currentDraft?.status, DraftCommandStatus.syncing);

    await manager.finishSync();

    expect(manager.currentDraft?.status, DraftCommandStatus.synced);
    expect(manager.messages.last.messageType, ChatMessageType.syncComplete);
    expect(manager.messages.last.text, 'ASON Core에 동기화할 준비가 완료되었습니다.');

    final saved = await MemoCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.content, 'ASON 음성 앱 다국어 지원');
  });

  test('내용을 수정한 뒤 다시 동기화하면 같은 항목이 최신 내용으로 덮어써진다', () async {
    final manager = ConversationManager();

    manager.handleUserText('메모가 있어');
    manager.handleUserText('초안');
    expect(manager.currentDraft?.status, DraftCommandStatus.ready);

    // 수정 버튼: 같은 draft(같은 createdAt)를 유지한 채 내용만 바꾼다.
    manager.beginEdit();
    manager.handleUserText('내용을 두 번째 메모로 바꿔줘');

    manager.beginSync();
    await manager.finishSync();

    final saved = await MemoCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.content, contains('두 번째 메모'));
  });
}
