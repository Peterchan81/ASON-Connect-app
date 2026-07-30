// SupabaseSyncService가 docs/CORE_CONNECT_SHARED_SCHEMA.md의 컬럼명을 그대로
// 따르는지, .env가 없을 때나 insert가 실패할 때도 예외를 던지지 않는지
// 검증합니다. 실제 네트워크/DB를 전혀 쓰지 않고, 가짜 SupabaseRowInserter로
// "어떤 테이블에 어떤 JSON을 보내려 했는지"만 기록해 확인합니다.

import 'package:ason_voice_app/features/core_sync/models/home_goal_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/home_schedule_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/memo_model.dart';
import 'package:ason_voice_app/features/core_sync/services/supabase_sync_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordedInsert {
  const _RecordedInsert(this.table, this.row);
  final String table;
  final Map<String, dynamic> row;
}

class _FakeInserter implements SupabaseRowInserter {
  final List<_RecordedInsert> calls = [];
  Object? errorToThrow;

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    if (errorToThrow != null) throw errorToThrow!;
    calls.add(_RecordedInsert(table, row));
  }
}

void main() {
  void configureEnv() {
    dotenv.testLoad(
      fileInput:
          'SUPABASE_URL=https://example.supabase.co\n'
          'SUPABASE_ANON_KEY=test-anon-key',
    );
  }

  group('isConfigured', () {
    test('.env가 로드되지 않았으면 false다', () {
      // 이 그룹 전용으로, 아래 configureEnv()를 호출하지 않은 상태를 확인합니다.
      final service = SupabaseSyncService(inserter: _FakeInserter());
      // dotenv가 이 테스트 파일의 다른 테스트에서 이미 testLoad됐을 수 있으므로
      // 순서에 의존하지 않도록, 빈 값으로 다시 로드해 명시적으로 재현합니다.
      dotenv.testLoad(fileInput: '');
      expect(service.isConfigured, isFalse);
    });

    test('SUPABASE_URL/ANON_KEY가 채워지면 true다', () {
      configureEnv();
      final service = SupabaseSyncService(inserter: _FakeInserter());
      expect(service.isConfigured, isTrue);
    });
  });

  group('.env가 설정되지 않으면 insert 자체를 시도하지 않는다', () {
    test('가짜 inserter가 호출되지 않는다', () async {
      dotenv.testLoad(fileInput: '');
      final fake = _FakeInserter();
      final service = SupabaseSyncService(inserter: fake);

      await service.insertSchedule(
        HomeScheduleEntry(
          id: 's1',
          date: DateTime(2026, 8, 3),
          time: '15:00',
          title: '병원',
          isDone: false,
        ),
      );
      expect(fake.calls, isEmpty);
    });
  });

  group('스키마 매핑(Shared Schema 컬럼명 그대로)', () {
    late _FakeInserter fake;
    late SupabaseSyncService service;

    setUp(() {
      configureEnv();
      fake = _FakeInserter();
      service = SupabaseSyncService(inserter: fake);
    });

    test('insertSchedule -> schedules 테이블, 컬럼명이 문서와 일치', () async {
      final entry = HomeScheduleEntry(
        id: 'sched_1',
        date: DateTime(2026, 8, 3),
        time: '15:00',
        title: '병원 방문',
        isDone: false,
        memo: '진료 예약',
        alarmEnabled: true,
      );

      await service.insertSchedule(entry);

      expect(fake.calls, hasLength(1));
      final call = fake.calls.single;
      expect(call.table, 'schedules');
      expect(call.row, {
        'id': 'sched_1',
        'schedule_date': '2026-08-03',
        'time_text': '15:00',
        'title': '병원 방문',
        'is_done': false,
        'memo': '진료 예약',
        'alarm_enabled': true,
        'source_app': 'connect',
        'is_deleted': false,
        'sync_version': 1,
      });
    });

    test('insertGoal -> daily_goals 테이블, goal_date는 보내지 않는다(DB 기본값에 위임)', () async {
      const entry = HomeGoalEntry(id: 'goal_1', title: '매일 걷기', isDone: false);

      await service.insertGoal(entry);

      final call = fake.calls.single;
      expect(call.table, 'daily_goals');
      expect(call.row, {
        'id': 'goal_1',
        'title': '매일 걷기',
        'is_done': false,
        'source_app': 'connect',
        'is_deleted': false,
        'sync_version': 1,
      });
      expect(call.row.containsKey('goal_date'), isFalse);
    });

    test('insertDiaryEntry -> diary_entries 테이블', () async {
      await service.insertDiaryEntry(
        id: 'diary_1',
        date: DateTime(2026, 7, 30),
        content: '오늘 기분이 좋았다',
      );

      final call = fake.calls.single;
      expect(call.table, 'diary_entries');
      expect(call.row, {
        'id': 'diary_1',
        'entry_date': '2026-07-30',
        'content': '오늘 기분이 좋았다',
        'source_app': 'connect',
        'is_deleted': false,
        'sync_version': 1,
      });
    });

    test('insertMemo -> memos 테이블, createdAt/updatedAt은 모델 값을 그대로 쓴다', () async {
      final memo = MemoModel(
        id: 'memo_1',
        title: '우유 사기',
        content: '우유 사기',
        category: '기타',
        tags: const ['장보기'],
        createdAt: DateTime(2026, 7, 30, 9, 0),
        updatedAt: DateTime(2026, 7, 30, 9, 30),
        isImportant: true,
        alarmEnabled: false,
      );

      await service.insertMemo(memo);

      final call = fake.calls.single;
      expect(call.table, 'memos');
      expect(call.row, {
        'id': 'memo_1',
        'title': '우유 사기',
        'content': '우유 사기',
        'category': '기타',
        'tags': ['장보기'],
        'is_important': true,
        'alarm_enabled': false,
        'created_at': DateTime(2026, 7, 30, 9, 0).toIso8601String(),
        'updated_at': DateTime(2026, 7, 30, 9, 30).toIso8601String(),
        'source_app': 'connect',
        'is_deleted': false,
        'sync_version': 1,
      });
    });
  });

  group('실패 처리: 어떤 경우에도 예외를 던지지 않는다', () {
    test('inserter가 예외를 던져도 SupabaseSyncService는 예외를 전파하지 않는다', () async {
      configureEnv();
      final fake = _FakeInserter()..errorToThrow = Exception('network down');
      final service = SupabaseSyncService(inserter: fake);

      // throwsA가 아니라, 정상적으로 완료되는지(예외 없이)를 확인합니다.
      await service.insertGoal(
        const HomeGoalEntry(id: 'g', title: 't', isDone: false),
      );
      // 여기까지 도달하면 예외가 전파되지 않은 것입니다.
    });
  });
}
