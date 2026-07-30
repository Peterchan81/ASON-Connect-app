// Brain Engine이 만든 DraftCommand(ready 상태)를 ASON-Core와 같은 구조의 모델로
// 바꿔서 저장소에 그대로 연결하는 단일 통로입니다. 카테고리별로 다른 저장
// 로직을 따로 만들지 않고, 이 클래스 하나만 거쳐 upsert합니다. 같은 draft가
// 수정 후 다시 동기화되어도 같은 id로 upsert되므로 중복 저장되지 않습니다.
//
// 일정은 추가로, 같은 날짜/시간/제목을 가진 "다른" 항목이 이미 있으면(완전히
// 동일한 일정을 실수로 두 번 만든 경우) 저장을 막고 duplicate 결과를 돌려줍니다.
//
// 역할 범위(중요): 여기서 말하는 "동기화"는 기기 안 SharedPreferences에 ASON-Core와
// 동일한 키·JSON 구조로 값을 써 두는 로컬 저장 단계입니다. ASON Connect와 ASON-Core는
// 서로 다른 앱(별도 프로세스/샌드박스)이라 이 클래스가 두 앱을 실시간으로 잇는 실제
// 앱 간 동기화 수단은 아닙니다 — 지금은 데이터 형태를 미리 맞춰 두는 로컬 임시
// 저장·형식 검증 단계이며, 두 앱이 실제로 데이터를 주고받으려면 이후 Supabase 등
// 서버 기반 동기화로 교체될 예정입니다.

import '../../ason_connect/models/draft_command.dart';
import '../models/health_entry.dart';
import '../models/home_goal_entry.dart';
import '../models/home_schedule_entry.dart';
import '../models/memo_model.dart';
import '../models/project_entry.dart';
import 'diary_core_repository.dart';
import 'field_normalizer.dart';
import 'goal_core_repository.dart';
import 'health_core_repository.dart';
import 'memo_core_repository.dart';
import 'project_core_repository.dart';
import 'schedule_core_repository.dart';
import 'supabase_sync_service.dart';

/// [CoreSyncMapper.sync] 결과입니다. 성공/중복/실패를 구분해 화면이 알맞은
/// 안내를 보여줄 수 있게 합니다.
class CoreSyncResult {
  const CoreSyncResult.success()
    : isSuccess = true,
      isDuplicate = false,
      errorMessage = null;

  const CoreSyncResult.duplicate(String message)
    : isSuccess = false,
      isDuplicate = true,
      errorMessage = message;

  const CoreSyncResult.failure(String message)
    : isSuccess = false,
      isDuplicate = false,
      errorMessage = message;

  final bool isSuccess;
  final bool isDuplicate;
  final String? errorMessage;
}

class CoreSyncMapper {
  CoreSyncMapper({
    ScheduleCoreRepository? scheduleRepository,
    MemoCoreRepository? memoRepository,
    HealthCoreRepository? healthRepository,
    ProjectCoreRepository? projectRepository,
    GoalCoreRepository? goalRepository,
    DiaryCoreRepository? diaryRepository,
    SupabaseSyncService? supabaseSyncService,
  }) : _scheduleRepository = scheduleRepository ?? ScheduleCoreRepository(),
       _memoRepository = memoRepository ?? MemoCoreRepository(),
       _healthRepository = healthRepository ?? HealthCoreRepository(),
       _projectRepository = projectRepository ?? ProjectCoreRepository(),
       _goalRepository = goalRepository ?? GoalCoreRepository(),
       _diaryRepository = diaryRepository ?? DiaryCoreRepository(),
       _supabaseSyncService = supabaseSyncService ?? SupabaseSyncService();

  final ScheduleCoreRepository _scheduleRepository;
  final MemoCoreRepository _memoRepository;
  final HealthCoreRepository _healthRepository;
  final ProjectCoreRepository _projectRepository;
  final GoalCoreRepository _goalRepository;
  final DiaryCoreRepository _diaryRepository;
  // 로컬 저장이 끝난 뒤 같은 데이터를 Supabase에도 추가로 남기는 보조
  // 경로입니다. 이 서비스의 모든 메서드는 내부에서 오류를 삼키므로(자세한
  // 설명은 supabase_sync_service.dart 참고), 여기서 별도로 try/catch하지
  // 않아도 로컬 저장 결과(CoreSyncResult)에 영향을 주지 않습니다.
  final SupabaseSyncService _supabaseSyncService;

  static const List<String> _memoIdeaCategory = ['아이디어'];

  /// 이 draft가 저장될 때 사용할 id입니다. 같은 draft(같은 createdAt)는 항상
  /// 같은 id로 계산되므로, 수정 후 다시 동기화해도 upsert가 덮어쓰기로
  /// 동작합니다(중복 생성 방지).
  String idFor(DraftCommand draft) =>
      'voice_${draft.createdAt.microsecondsSinceEpoch}';

  /// draft를 같은 주제(같은 createdAt→같은 id)의 기존 저장 항목이 있으면
  /// 덮어쓰고, 없으면 새로 저장합니다. 일정은 저장 전에 완전히 동일한(다른
  /// id의) 일정이 이미 있는지 먼저 확인해, 있으면 저장하지 않고 duplicate로
  /// 알려줍니다.
  Future<CoreSyncResult> sync(DraftCommand draft) async {
    final category = draft.category;
    if (category == null) {
      return const CoreSyncResult.failure('분류되지 않은 내용은 동기화할 수 없습니다.');
    }
    // UI(SchedulePreviewPanel)가 이미 동기화 버튼을 비활성화하지만, 이 검증에만
    // 기대지 않고 저장 직전에 한 번 더 막습니다. 여기서 걸리면 아무 것도 쓰지
    // 않고(placeholder "-"로도 대신 채우지 않고) 실패로 돌려줍니다.
    if (!draft.hasRequiredContent) {
      return const CoreSyncResult.failure('내용이 없어 동기화할 수 없습니다.');
    }
    final id = idFor(draft);

    switch (category) {
      case DraftCommandCategory.schedule:
      case DraftCommandCategory.todo:
        final entry = _toScheduleEntry(id, draft);
        final duplicate = await _findDuplicateSchedule(entry);
        if (duplicate != null) {
          return const CoreSyncResult.duplicate('이미 동일한 일정이 있습니다.');
        }
        await _scheduleRepository.upsert(entry);
        // 로컬 저장이 이미 끝난 뒤에만 시도합니다 — Supabase 실패가 위의
        // upsert 성공 여부에 영향을 주지 않습니다.
        await _supabaseSyncService.insertSchedule(entry);
      case DraftCommandCategory.memo:
        final memo = _toMemoModel(id, draft);
        await _memoRepository.upsert(memo);
        await _supabaseSyncService.insertMemo(memo);
      case DraftCommandCategory.health:
        await _healthRepository.upsert(_toHealthEntry(id, draft));
      case DraftCommandCategory.project:
        await _projectRepository.upsert(_toProjectEntry(id, draft));
      case DraftCommandCategory.dailyGoal:
        final goal = _toGoalEntry(id, draft);
        await _goalRepository.upsert(goal);
        await _supabaseSyncService.insertGoal(goal);
      case DraftCommandCategory.diary:
        // id 기반으로 저장합니다: 같은 draft(같은 id)를 수정 후 다시 동기화해도
        // 줄이 중복으로 늘어나지 않고 그 줄만 최신 내용으로 바뀝니다.
        final diaryDate = FieldNormalizer.resolveDate(draft.date);
        final diaryContent = (draft.title ?? '-').trim();
        await _diaryRepository.upsert(diaryDate, id, diaryContent);
        await _supabaseSyncService.insertDiaryEntry(
          id: id,
          date: diaryDate,
          content: diaryContent,
        );
    }
    return const CoreSyncResult.success();
  }

  /// 같은 날짜에 (id는 다르지만) 시간·제목이 모두 같은 일정이 이미 있는지
  /// 확인합니다. 사용자 입력의 공백/대소문자 차이는 같은 일정으로 취급합니다.
  Future<HomeScheduleEntry?> _findDuplicateSchedule(
    HomeScheduleEntry candidate,
  ) async {
    final existing = await _scheduleRepository.loadForDate(candidate.date);
    for (final entry in existing) {
      if (entry.id == candidate.id) continue;
      final sameTime = entry.time == candidate.time;
      final sameTitle =
          entry.title.trim().toLowerCase() ==
          candidate.title.trim().toLowerCase();
      if (sameTime && sameTitle) return entry;
    }
    return null;
  }

  HomeScheduleEntry _toScheduleEntry(String id, DraftCommand draft) {
    return HomeScheduleEntry(
      id: id,
      date: FieldNormalizer.resolveDate(draft.date),
      time: FieldNormalizer.normalizeTime(draft.time),
      title: (draft.title ?? '-').trim(),
      isDone: false,
      memo: draft.memo,
      alarmEnabled: draft.alarm != null && draft.alarm != '없음',
    );
  }

  MemoModel _toMemoModel(String id, DraftCommand draft) {
    final content = (draft.title ?? '-').trim();
    final category = _memoIdeaCategory.contains(draft.memoType)
        ? draft.memoType!
        : '기타';
    return MemoModel(
      id: id,
      title: content,
      content: content,
      category: category,
      tags: const [],
      createdAt: draft.createdAt,
      updatedAt: draft.updatedAt,
      isImportant: false,
      alarmEnabled: false,
    );
  }

  HealthEntry _toHealthEntry(String id, DraftCommand draft) {
    return HealthEntry(
      id: id,
      item: draft.healthItem ?? '증상',
      value: (draft.title ?? '-').trim(),
      date: draft.date,
      createdAt: draft.createdAt,
      updatedAt: draft.updatedAt,
    );
  }

  HomeGoalEntry _toGoalEntry(String id, DraftCommand draft) {
    return HomeGoalEntry(
      id: id,
      title: (draft.title ?? '-').trim(),
      isDone: false,
    );
  }

  ProjectEntry _toProjectEntry(String id, DraftCommand draft) {
    return ProjectEntry(
      id: id,
      title: (draft.title ?? '-').trim(),
      action: draft.projectAction ?? '생성',
      progress: draft.progress,
      createdAt: draft.createdAt,
      updatedAt: draft.updatedAt,
    );
  }
}
