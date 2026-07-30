// ASON Core와 공유하는 Supabase 테이블(schedules/daily_goals/diary_entries/
// memos)에 같은 데이터를 추가로 저장하는 서비스입니다. Phase 1 범위: insert만
// 하고, 조회(ASON Core가 Connect의 데이터를 읽어오는 기능)는 아직 구현하지
// 않습니다.
//
// 중요: 이 서비스는 CoreSyncMapper의 로컬(SharedPreferences) 저장을 절대
// 대체하지 않습니다. 로컬 저장이 이미 끝난 뒤에 "추가로" 호출되는 보조
// 경로이며, 여기서 나는 모든 오류(네트워크 실패, .env 미설정, 초기화 안 됨,
// RLS 거부 등)는 로그만 남기고 항상 삼킵니다 — 이 서비스의 어떤 메서드도
// 예외를 밖으로 던지지 않습니다. Supabase 저장이 실패해도 사용자의 로컬
// 데이터는 이미 안전하게 저장되어 있어야 하기 때문입니다.
//
// 컬럼명은 docs/CORE_CONNECT_SHARED_SCHEMA.md를 그대로 따릅니다(임의 변경
// 없음). user_id는 채우지 않습니다 — Connect는 아직 Supabase Auth 세션이
// 없어(문서의 "Phase 2 이전에 확인이 필요한 전제" 참고) 신뢰할 수 있는
// user_id를 만들 수 없고, 잘못된 값을 지어내는 것은 이번 작업의 "임시 변환
// 금지" 원칙에 어긋납니다. user_id 없이 보낸 insert는 RLS 정책상 대부분
// 거부되겠지만, 그 실패도 이 서비스 안에서 조용히 처리됩니다(Phase 2에서
// 두 앱의 로그인 흐름이 Supabase Auth 세션을 만들도록 확장되면 채워질 예정).

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_goal_entry.dart';
import '../models/home_schedule_entry.dart';
import '../models/memo_model.dart';

/// Supabase insert 호출 자체를 감싸는 최소 인터페이스입니다. 실제 구현은
/// `Supabase.instance.client`를 쓰고, 테스트에서는 실 DB를 전혀 건드리지
/// 않는 가짜 구현을 주입해 "이 테이블에 이 JSON을 보내려 했다"만 기록합니다.
abstract class SupabaseRowInserter {
  Future<void> insert(String table, Map<String, dynamic> row);
}

class _RealSupabaseRowInserter implements SupabaseRowInserter {
  const _RealSupabaseRowInserter();

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    // Supabase.initialize()가 호출된 적이 없으면 Supabase.instance 접근
    // 자체가 예외를 던질 수 있습니다 — 이 메서드를 부르는 쪽(SupabaseSyncService
    // 의 _safeInsert)이 항상 try/catch로 감싸므로 여기서 별도로 막지 않아도
    // 앱이 죽지 않습니다.
    await Supabase.instance.client.from(table).insert(row);
  }
}

class SupabaseSyncService {
  SupabaseSyncService({SupabaseRowInserter? inserter})
    : _inserter = inserter ?? const _RealSupabaseRowInserter();

  final SupabaseRowInserter _inserter;

  static const String _sourceApp = 'connect';
  static const int _initialSyncVersion = 1;

  /// `.env`의 SUPABASE_URL/SUPABASE_ANON_KEY가 채워져 있어 Supabase를 쓸
  /// 준비가 됐는지입니다. 준비되지 않았으면 insert 시도 자체를 생략하고
  /// 그 이유를 한 번만 로그로 남깁니다(어차피 실패할 네트워크 호출을 굳이
  /// 만들지 않습니다).
  bool get isConfigured {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      return url != null &&
          url.isNotEmpty &&
          anonKey != null &&
          anonKey.isNotEmpty;
    } catch (_) {
      // dotenv.load()가 호출된 적이 없어도(테스트 환경 등) 크래시하지 않습니다.
      return false;
    }
  }

  Map<String, dynamic> get _commonDefaults => {
    'source_app': _sourceApp,
    'is_deleted': false,
    'sync_version': _initialSyncVersion,
  };

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 오류를 항상 이 안에서 처리합니다. 호출한 쪽은 결과를 기다릴 필요도,
  /// try/catch할 필요도 없습니다 — 이 메서드는 절대 예외를 던지지 않습니다.
  Future<void> _safeInsert(String table, Map<String, dynamic> row) async {
    if (!isConfigured) {
      debugPrint(
        'SupabaseSyncService: SUPABASE_URL/ANON_KEY가 설정되지 않아 '
        '"$table" insert를 건너뜁니다(로컬 저장은 이미 완료된 상태입니다).',
      );
      return;
    }
    try {
      await _inserter.insert(table, row);
    } catch (error) {
      debugPrint(
        'SupabaseSyncService: "$table" insert 실패(로컬 저장에는 영향 없음): '
        '$error',
      );
    }
  }

  /// schedules 테이블에 일정 한 건을 insert합니다.
  Future<void> insertSchedule(HomeScheduleEntry entry) {
    return _safeInsert('schedules', {
      'id': entry.id,
      'schedule_date': _dateOnly(entry.date),
      'time_text': entry.time,
      'title': entry.title,
      'is_done': entry.isDone,
      if (entry.memo != null) 'memo': entry.memo,
      'alarm_enabled': entry.alarmEnabled,
      ..._commonDefaults,
    });
  }

  /// daily_goals 테이블에 목표 한 건을 insert합니다. `goal_date`는 일부러
  /// 채우지 않습니다 — Shared Schema 문서상 `HomeGoalEntry`엔 원래 날짜가
  /// 없고, 테이블 쪽에 `default current_date`가 이미 있어 DB가 채웁니다.
  Future<void> insertGoal(HomeGoalEntry entry) {
    return _safeInsert('daily_goals', {
      'id': entry.id,
      'title': entry.title,
      'is_done': entry.isDone,
      ..._commonDefaults,
    });
  }

  /// diary_entries 테이블에 날짜당 한 줄 기록을 insert합니다.
  Future<void> insertDiaryEntry({
    required String id,
    required DateTime date,
    required String content,
  }) {
    return _safeInsert('diary_entries', {
      'id': id,
      'entry_date': _dateOnly(date),
      'content': content,
      ..._commonDefaults,
    });
  }

  /// memos 테이블에 메모 한 건을 insert합니다. `createdAt`/`updatedAt`은
  /// `MemoModel`이 이미 갖고 있는 값을 그대로 씁니다(다른 필드처럼 DB
  /// 기본값에 맡기지 않습니다 — 나중에 값을 지어내 덮어쓰지 않기 위해).
  Future<void> insertMemo(MemoModel memo) {
    return _safeInsert('memos', {
      'id': memo.id,
      'title': memo.title,
      'content': memo.content,
      'category': memo.category,
      'tags': memo.tags,
      'is_important': memo.isImportant,
      'alarm_enabled': memo.alarmEnabled,
      if (memo.alarmDateTime != null)
        'alarm_at': memo.alarmDateTime!.toIso8601String(),
      if (memo.startDate != null) 'start_date': _dateOnly(memo.startDate!),
      if (memo.endDate != null) 'end_date': _dateOnly(memo.endDate!),
      'created_at': memo.createdAt.toIso8601String(),
      'updated_at': memo.updatedAt.toIso8601String(),
      ..._commonDefaults,
    });
  }
}
