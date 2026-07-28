// Brain Engine이 만든 DraftCommand(ready 상태)를 ASON-Core와 같은 구조의 모델로
// 바꿔서 저장소에 그대로 연결하는 단일 통로입니다. 카테고리별로 다른 저장
// 로직을 따로 만들지 않고, 이 클래스 하나만 거쳐 upsert합니다. 같은 draft가
// 수정 후 다시 동기화되어도 같은 id로 upsert되므로 중복 저장되지 않습니다.

import '../../ason_connect/models/draft_command.dart';
import '../models/health_entry.dart';
import '../models/home_schedule_entry.dart';
import '../models/memo_model.dart';
import '../models/project_entry.dart';
import 'health_core_repository.dart';
import 'memo_core_repository.dart';
import 'project_core_repository.dart';
import 'schedule_core_repository.dart';

class CoreSyncMapper {
  CoreSyncMapper({
    ScheduleCoreRepository? scheduleRepository,
    MemoCoreRepository? memoRepository,
    HealthCoreRepository? healthRepository,
    ProjectCoreRepository? projectRepository,
  }) : _scheduleRepository = scheduleRepository ?? ScheduleCoreRepository(),
       _memoRepository = memoRepository ?? MemoCoreRepository(),
       _healthRepository = healthRepository ?? HealthCoreRepository(),
       _projectRepository = projectRepository ?? ProjectCoreRepository();

  final ScheduleCoreRepository _scheduleRepository;
  final MemoCoreRepository _memoRepository;
  final HealthCoreRepository _healthRepository;
  final ProjectCoreRepository _projectRepository;

  static const List<String> _memoIdeaCategory = ['아이디어'];

  /// draft를 같은 주제(같은 createdAt)의 기존 저장 항목이 있으면 덮어쓰고,
  /// 없으면 새로 저장합니다.
  Future<void> sync(DraftCommand draft) async {
    final category = draft.category;
    if (category == null) return;
    final id = 'voice_${draft.createdAt.microsecondsSinceEpoch}';

    switch (category) {
      case DraftCommandCategory.schedule:
      case DraftCommandCategory.todo:
        await _scheduleRepository.upsert(_toScheduleEntry(id, draft));
      case DraftCommandCategory.memo:
        await _memoRepository.upsert(_toMemoModel(id, draft));
      case DraftCommandCategory.health:
        await _healthRepository.upsert(_toHealthEntry(id, draft));
      case DraftCommandCategory.project:
        await _projectRepository.upsert(_toProjectEntry(id, draft));
    }
  }

  HomeScheduleEntry _toScheduleEntry(String id, DraftCommand draft) {
    return HomeScheduleEntry(
      id: id,
      date: _resolveDate(draft.date),
      time: _toHHmm(draft.time),
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

  /// "내일"/"오늘"처럼 상대적인 한글 표현이나 "8월 15일" 형식을 실제 날짜로
  /// 바꿉니다. 알 수 없으면 오늘 날짜를 씁니다.
  DateTime _resolveDate(String? koreanDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (koreanDate) {
      case '오늘':
        return today;
      case '내일':
        return today.add(const Duration(days: 1));
      case '모레':
        return today.add(const Duration(days: 2));
      case '어제':
        return today.subtract(const Duration(days: 1));
    }
    if (koreanDate != null) {
      final match = RegExp(r'(\d{1,2})월\s*(\d{1,2})일').firstMatch(koreanDate);
      if (match != null) {
        final month = int.parse(match.group(1)!);
        final day = int.parse(match.group(2)!);
        return DateTime(today.year, month, day);
      }
    }
    return today;
  }

  /// "오후 3시"/"오전 10시 30분" 같은 한글 시간 표현을 ASON-Core가 쓰는
  /// "HH:mm" 24시간 형식으로 바꿉니다. 알 수 없으면 "--:--"(시간 없음)입니다.
  String _toHHmm(String? koreanTime) {
    if (koreanTime == null) return '--:--';
    final match = RegExp(
      r'(오전|오후)?\s*(\d{1,2})시\s*(\d{1,2})?분?',
    ).firstMatch(koreanTime);
    if (match == null) return '--:--';

    var hour = int.tryParse(match.group(2) ?? '') ?? 0;
    final minute = int.tryParse(match.group(3) ?? '') ?? 0;
    final isPm = match.group(1) == '오후';
    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
