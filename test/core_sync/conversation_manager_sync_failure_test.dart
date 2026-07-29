// ConversationManager의 동기화 실패/중복 처리와, 전송 전 실시간 미리보기가
// 실제 대화 상태를 바꾸지 않는지 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('완전히 동일한 일정이 이미 있으면 동기화가 실패로 처리되고 이유가 남는다', () async {
    final first = ConversationManager();
    first.handleUserText('내일 오후 3시 영동에서 광고미팅');
    expect(first.currentDraft?.status, DraftCommandStatus.ready);
    first.beginSync();
    await first.finishSync();
    expect(first.currentDraft?.status, DraftCommandStatus.synced);
    expect(first.lastSyncError, isNull);

    // 같은 날짜/시간/제목으로 완전히 새로운(다른 id) 일정을 또 만듭니다.
    final second = ConversationManager();
    second.handleUserText('내일 오후 3시 영동에서 광고미팅');
    expect(second.currentDraft?.status, DraftCommandStatus.ready);

    second.beginSync();
    await second.finishSync();

    expect(second.currentDraft?.status, DraftCommandStatus.ready);
    expect(second.lastSyncError, '이미 동일한 일정이 있습니다.');
    expect(
      second.messages.last.text,
      '이미 동일한 일정이 있습니다.',
    );
  });

  test('previewDraft는 실제 draft나 채팅 이력을 전혀 바꾸지 않는 순수 미리보기다', () {
    final manager = ConversationManager();
    final messageCountBefore = manager.messages.length;

    final preview = manager.previewDraft('내일 오후 3시 영동에서 광고미팅');

    expect(preview, isNotNull);
    expect(preview!.category, DraftCommandCategory.schedule);
    expect(preview.title, contains('광고미팅'));
    // 실제 상태는 그대로입니다: 아직 아무 것도 전송하지 않았습니다.
    expect(manager.currentDraft, isNull);
    expect(manager.messages.length, messageCountBefore);
  });

  test('updateDraftField는 자연어 재해석 없이 값만 바로 덮어쓴다', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시 영동에서 광고미팅');
    expect(manager.currentDraft?.status, DraftCommandStatus.ready);

    manager.updateDraftField(location: '유성구');

    expect(manager.currentDraft?.location, '유성구');
    expect(manager.currentDraft?.status, DraftCommandStatus.ready);
  });
}
