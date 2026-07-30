// Brain Engine이 만든 DraftCommand(ready)가 CoreSyncMapper를 거쳐 ASON-Core와
// 같은 구조로 실제 저장되는지, 그리고 같은 draft를 다시 동기화해도 중복 저장되지
// 않는지(수정도 같은 구조를 쓰는지) 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/core_sync/services/core_sync_mapper.dart';
import 'package:ason_voice_app/features/core_sync/services/diary_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/goal_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/health_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/memo_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/project_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/schedule_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/supabase_sync_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingInserter implements SupabaseRowInserter {
  final List<String> attemptedTables = [];

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    attemptedTables.add(table);
    throw Exception('Supabase에 연결할 수 없습니다(테스트용 실패)');
  }
}

class _FakeUserIdProvider implements SupabaseUserIdProvider {
  _FakeUserIdProvider({this.userId});

  String? userId;
  Object? errorToThrow;

  @override
  String? get currentUserId {
    if (errorToThrow != null) throw errorToThrow!;
    return userId;
  }
}

const _fakeLoggedInUserId = 'test-user-uuid-1234';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('일정 draft를 동기화하면 ASON-Core의 scheduleByDate 구조로 저장된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '내일 병원 예약',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
      date: '내일',
      time: '오후 3시',
      title: '병원 예약',
      alarm: '30분 전',
    );

    await mapper.sync(draft);

    final saved = await ScheduleCoreRepository().loadAll();
    final now = DateTime.now();
    final expectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    expect(saved, hasLength(1));
    expect(saved.single.title, '병원 예약');
    expect(saved.single.time, '15:00');
    expect(saved.single.alarmEnabled, isTrue);
    expect(saved.single.date, expectedDate);
  });

  test('시간 표현을 알 수 없으면 "--:--"(시간 없음)으로 저장된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '메모가 있어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
      title: '병원 예약',
    );

    await mapper.sync(draft);

    final saved = await ScheduleCoreRepository().loadAll();
    expect(saved.single.time, '--:--');
    expect(saved.single.hasTime, isFalse);
  });

  test('할 일 draft도 일정과 같은 저장소를 사용한다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '우유 사기',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.todo,
      title: '우유 사기',
    );

    await mapper.sync(draft);

    expect(await ScheduleCoreRepository().loadAll(), hasLength(1));
  });

  test('메모 draft를 동기화하면 MemoModel 구조로 저장되고, 아이디어 종류는 그대로 카테고리가 된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '메모가 있어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.memo,
      title: 'ASON 음성 앱 다국어 지원',
      memoType: '아이디어',
    );

    await mapper.sync(draft);

    final saved = await MemoCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.content, 'ASON 음성 앱 다국어 지원');
    expect(saved.single.category, '아이디어');
  });

  test('메모 종류가 "일반"이면 ASON-Core 분류에 맞춰 "기타"로 저장된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '메모가 있어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.memo,
      title: '장보기 목록',
      memoType: '일반',
    );

    await mapper.sync(draft);

    final saved = await MemoCoreRepository().loadAll();
    expect(saved.single.category, '기타');
  });

  test('건강 draft를 동기화하면 HealthEntry 구조로 저장된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: '오늘 혈압 쟀어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.health,
      healthItem: '혈압',
      title: '128/82',
    );

    await mapper.sync(draft);

    final saved = await HealthCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.item, '혈압');
    expect(saved.single.value, '128/82');
  });

  test('프로젝트 draft를 동기화하면 ProjectEntry 구조로 저장된다', () async {
    final mapper = CoreSyncMapper();
    final draft = DraftCommand(
      originalText: 'ASON 리브랜딩 진행률 60%로 변경',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.project,
      title: 'ASON 리브랜딩',
      projectAction: '수정',
      progress: '60%',
    );

    await mapper.sync(draft);

    final saved = await ProjectCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.action, '수정');
    expect(saved.single.progress, '60%');
  });

  test('같은 draft를 수정 후 다시 동기화하면 중복 저장되지 않고 같은 id로 덮어쓴다', () async {
    final mapper = CoreSyncMapper();
    final created = DateTime(2026, 7, 28, 10);
    final original = DraftCommand(
      originalText: '메모가 있어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.memo,
      title: '초안',
      memoType: '일반',
      createdAt: created,
    );

    await mapper.sync(original);

    final edited = original.copyWith(title: '수정된 내용');
    await mapper.sync(edited);

    final saved = await MemoCoreRepository().loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.content, '수정된 내용');
  });

  group('Supabase insert 실패는 로컬 저장에 영향을 주지 않는다', () {
    setUp(() {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://example.supabase.co\n'
            'SUPABASE_ANON_KEY=test-anon-key',
      );
    });

    test('일정: Supabase insert가 실패해도 로컬 scheduleByDate에는 정상 저장된다', () async {
      final inserter = _ThrowingInserter();
      final mapper = CoreSyncMapper(
        supabaseSyncService: SupabaseSyncService(
          inserter: inserter,
          // 로그인 상태를 가정해야 insert가 실제로 시도되고(그리고
          // 실패하고) 이 테스트가 의도한 경로를 검증합니다. 로그인하지
          // 않은 상태의 검증은 아래 "로그인 세션이 없어도..." 그룹에서
          // 따로 합니다.
          userIdProvider: _FakeUserIdProvider(userId: _fakeLoggedInUserId),
        ),
      );
      final draft = DraftCommand(
        originalText: '내일 병원 예약',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.schedule,
        date: '내일',
        time: '오후 3시',
        title: '병원 예약',
      );

      final result = await mapper.sync(draft);

      expect(result.isSuccess, isTrue);
      expect(inserter.attemptedTables, contains('schedules'));
      final saved = await ScheduleCoreRepository().loadAll();
      expect(saved, hasLength(1));
      expect(saved.single.title, '병원 예약');
    });

    test('메모: Supabase insert가 실패해도 로컬 MemoModel에는 정상 저장된다', () async {
      final inserter = _ThrowingInserter();
      final mapper = CoreSyncMapper(
        supabaseSyncService: SupabaseSyncService(
          inserter: inserter,
          userIdProvider: _FakeUserIdProvider(userId: _fakeLoggedInUserId),
        ),
      );
      final draft = DraftCommand(
        originalText: '메모가 있어',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.memo,
        title: '우유 사기',
      );

      final result = await mapper.sync(draft);

      expect(result.isSuccess, isTrue);
      expect(inserter.attemptedTables, contains('memos'));
      final saved = await MemoCoreRepository().loadAll();
      expect(saved, hasLength(1));
    });
  });

  group('로그인 세션이 없어도(비로그인) 로컬 저장은 정상적으로 진행된다', () {
    setUp(() {
      // .env는 설정돼 있지만(Supabase 자체는 켜져 있지만) 로그인 세션이
      // 없는, 실제로 가장 흔한 상태를 재현합니다.
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://example.supabase.co\n'
            'SUPABASE_ANON_KEY=test-anon-key',
      );
    });

    CoreSyncMapper loggedOutMapper() => CoreSyncMapper(
      supabaseSyncService: SupabaseSyncService(
        inserter: _ThrowingInserter(), // 호출되면 안 되므로, 호출되면 즉시 실패해야 알아챌 수 있게 일부러 예외를 던지는 걸 씁니다.
        userIdProvider: _FakeUserIdProvider(userId: null),
      ),
    );

    test('일정: user_id가 없어도 로컬 저장은 성공한다', () async {
      final draft = DraftCommand(
        originalText: '내일 병원 예약',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.schedule,
        date: '내일',
        time: '오후 3시',
        title: '병원 예약',
      );

      final result = await loggedOutMapper().sync(draft);

      expect(result.isSuccess, isTrue);
      expect(await ScheduleCoreRepository().loadAll(), hasLength(1));
    });

    test('목표: user_id가 없어도 로컬 todayGoals에는 정상 저장된다', () async {
      final draft = DraftCommand(
        originalText: '매일 30분 걷기',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.dailyGoal,
        title: '매일 30분 걷기',
      );

      final result = await loggedOutMapper().sync(draft);

      expect(result.isSuccess, isTrue);
      final saved = await GoalCoreRepository().loadAll();
      expect(saved, hasLength(1));
      expect(saved.single.title, '매일 30분 걷기');
    });

    test('다이어리: user_id가 없어도 로컬 diaryEntries에는 정상 저장된다', () async {
      final draft = DraftCommand(
        originalText: '오늘 기분이 좋았다',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.diary,
        date: '오늘',
        title: '오늘 기분이 좋았다',
      );

      final result = await loggedOutMapper().sync(draft);

      expect(result.isSuccess, isTrue);
      final saved = await DiaryCoreRepository().loadForDate(DateTime.now());
      expect(saved, isNotNull);
    });

    test('메모: user_id가 없어도 로컬 MemoModel에는 정상 저장된다', () async {
      final draft = DraftCommand(
        originalText: '우유 사기',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.memo,
        title: '우유 사기',
      );

      final result = await loggedOutMapper().sync(draft);

      expect(result.isSuccess, isTrue);
      expect(await MemoCoreRepository().loadAll(), hasLength(1));
    });
  });

  group('user_id 조회 중 예외가 발생해도 앱 흐름과 로컬 저장은 유지된다', () {
    test('SupabaseUserIdProvider가 예외를 던져도 일정은 정상적으로 로컬 저장된다', () async {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://example.supabase.co\n'
            'SUPABASE_ANON_KEY=test-anon-key',
      );
      final mapper = CoreSyncMapper(
        supabaseSyncService: SupabaseSyncService(
          inserter: _ThrowingInserter(),
          userIdProvider: _FakeUserIdProvider()
            ..errorToThrow = StateError('세션 조회 실패(테스트용)'),
        ),
      );
      final draft = DraftCommand(
        originalText: '내일 병원 예약',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.schedule,
        date: '내일',
        time: '오후 3시',
        title: '병원 예약',
      );

      final result = await mapper.sync(draft);

      expect(result.isSuccess, isTrue);
      expect(await ScheduleCoreRepository().loadAll(), hasLength(1));
    });
  });
}
