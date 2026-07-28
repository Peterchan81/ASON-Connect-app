// CoreSyncMapper의 일정 저장/중복 방지 동작을 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/core_sync/services/core_sync_mapper.dart';
import 'package:ason_voice_app/features/core_sync/services/schedule_core_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DraftCommand _scheduleDraft({
  required String title,
  String date = '내일',
  String time = '오후 3시',
  String? location,
  DateTime? createdAt,
}) {
  return DraftCommand(
    originalText: title,
    status: DraftCommandStatus.ready,
    category: DraftCommandCategory.schedule,
    date: date,
    time: time,
    title: title,
    location: location,
    createdAt: createdAt,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('새 일정을 동기화하면 성공하고 저장소에 반영된다', () async {
    final mapper = CoreSyncMapper();
    final draft = _scheduleDraft(title: '광고미팅');

    final result = await mapper.sync(draft);

    expect(result.isSuccess, isTrue);
    final saved = await ScheduleCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.title, '광고미팅');
    expect(saved.single.time, '15:00');
  });

  test('같은 draft를 수정 후 다시 동기화하면 같은 id로 덮어써 중복 저장되지 않는다', () async {
    final mapper = CoreSyncMapper();
    final createdAt = DateTime.now();
    final draft = _scheduleDraft(title: '광고미팅', createdAt: createdAt);

    await mapper.sync(draft);
    final edited = draft.copyWith(title: '광고미팅(수정)');
    await mapper.sync(edited);

    final saved = await ScheduleCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.title, '광고미팅(수정)');
  });

  test('날짜/시간/제목이 완전히 같은 다른 일정이 이미 있으면 저장하지 않고 duplicate를 알려준다', () async {
    final mapper = CoreSyncMapper();
    final first = _scheduleDraft(
      title: '광고미팅',
      createdAt: DateTime(2026, 1, 1, 9),
    );
    final second = _scheduleDraft(
      title: '광고미팅',
      createdAt: DateTime(2026, 1, 1, 10),
    );

    final firstResult = await mapper.sync(first);
    final secondResult = await mapper.sync(second);

    expect(firstResult.isSuccess, isTrue);
    expect(secondResult.isSuccess, isFalse);
    expect(secondResult.isDuplicate, isTrue);
    expect(secondResult.errorMessage, '이미 동일한 일정이 있습니다.');

    final saved = await ScheduleCoreRepository().loadAll();
    expect(saved, hasLength(1));
  });

  test('제목이 다르면 같은 날짜/시간이어도 중복으로 취급하지 않는다', () async {
    final mapper = CoreSyncMapper();
    final first = _scheduleDraft(
      title: '광고미팅',
      createdAt: DateTime(2026, 1, 1, 9),
    );
    final second = _scheduleDraft(
      title: '다른 미팅',
      createdAt: DateTime(2026, 1, 1, 10),
    );

    await mapper.sync(first);
    final secondResult = await mapper.sync(second);

    expect(secondResult.isSuccess, isTrue);
    final saved = await ScheduleCoreRepository().loadAll();
    expect(saved, hasLength(2));
  });
}
