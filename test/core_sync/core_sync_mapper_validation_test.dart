// CoreSyncMapper가 UI 검증에만 기대지 않고, 핵심 내용이 없는 DraftCommand는
// 저장 직전에 한 번 더 막는지 검증합니다. "-" 같은 placeholder로 대신 채워
// 저장하지 않고, 아무 것도 쓰지 않은 채 실패를 돌려줘야 합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/core_sync/services/core_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DraftCommand _emptyDraft(DraftCommandCategory category) => DraftCommand(
  originalText: '원문',
  status: DraftCommandStatus.ready,
  category: category,
  date: '오늘',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('빈 일정은 scheduleByDate에 저장되지 않고 실패로 처리된다', () async {
    final result = await CoreSyncMapper().sync(
      _emptyDraft(DraftCommandCategory.schedule),
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, '내용이 없어 동기화할 수 없습니다.');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('scheduleByDate'), isNull);
  });

  test('빈 나의 하루 목표는 todayGoals에 저장되지 않는다', () async {
    final result = await CoreSyncMapper().sync(
      _emptyDraft(DraftCommandCategory.dailyGoal),
    );

    expect(result.isSuccess, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('todayGoals'), isNull);
  });

  test('빈 다이어리는 diaryEntries에 저장되지 않는다', () async {
    final result = await CoreSyncMapper().sync(
      _emptyDraft(DraftCommandCategory.diary),
    );

    expect(result.isSuccess, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('diaryEntries'), isNull);
  });

  test('빈 메모는 memoStoreV1에 저장되지 않는다', () async {
    final result = await CoreSyncMapper().sync(
      _emptyDraft(DraftCommandCategory.memo),
    );

    expect(result.isSuccess, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memoStoreV1'), isNull);
  });

  test('공백뿐인 title도 "-"로 대신 채워 저장하지 않는다', () async {
    final draft = DraftCommand(
      originalText: '원문',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.memo,
      title: '   ',
    );

    final result = await CoreSyncMapper().sync(draft);

    expect(result.isSuccess, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memoStoreV1'), isNull);
  });

  test('유효한 내용이 있으면 정상적으로 저장된다', () async {
    final draft = DraftCommand(
      originalText: '원문',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.memo,
      title: '우유와 계란 구매',
    );

    final result = await CoreSyncMapper().sync(draft);

    expect(result.isSuccess, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memoStoreV1'), isNotNull);
  });
}
