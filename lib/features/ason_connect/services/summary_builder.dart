// 확인 카드(Summary)에 보여줄 제목·행 목록과, ASON Core로 보낼 SyncPayload를
// DraftCommand 하나로부터 만들어 냅니다. 대화 상태(ConversationManager)와 분리해서,
// "지금 draft를 어떻게 정리해서 보여줄지"만 담당합니다.

import '../models/draft_command.dart';
import '../models/sync_payload.dart';

class SummaryBuilder {
  const SummaryBuilder();

  /// 확인 카드 제목입니다. 예: "일정 요약"
  String title(DraftCommand draft) => '${draft.category!.label} 요약';

  /// 확인 카드에 정해진 순서대로 보여줄 라벨-값 목록입니다.
  /// 일정은 반드시 시간 → 내용 → 장소 → 알림 → 반복 → 메모 순서로 보여줍니다.
  List<MapEntry<String, String>> rows(DraftCommand draft) {
    switch (draft.category!) {
      case DraftCommandCategory.schedule:
        return [
          MapEntry('시간', combinedTime(draft)),
          MapEntry('내용', draft.title ?? '-'),
          MapEntry('장소', draft.location ?? '-'),
          MapEntry('알림', draft.alarm ?? '없음'),
          MapEntry('반복', draft.repeatOption ?? '없음'),
          MapEntry('메모', draft.memo ?? '-'),
        ];
      case DraftCommandCategory.health:
        return [
          MapEntry('항목', draft.healthItem ?? '-'),
          MapEntry('내용', draft.title ?? '-'),
          MapEntry('날짜', draft.date ?? '-'),
        ];
      case DraftCommandCategory.memo:
        return [
          MapEntry('종류', draft.memoType ?? '일반'),
          MapEntry('내용', draft.title ?? '-'),
        ];
      case DraftCommandCategory.project:
        final rows = [
          MapEntry('활동', draft.projectAction ?? '생성'),
          MapEntry('내용', draft.title ?? '-'),
        ];
        if ((draft.progress ?? '').trim().isNotEmpty) {
          rows.add(MapEntry('진행률', draft.progress!));
        }
        return rows;
      case DraftCommandCategory.todo:
        return [MapEntry('내용', draft.title ?? '-')];
    }
  }

  /// 일정의 날짜+시간을 "오늘 오후 3시"처럼 하나의 표시용 문자열로 합칩니다.
  String combinedTime(DraftCommand draft) {
    final parts = [
      draft.date,
      draft.time,
    ].where((value) => value != null && value.trim().isNotEmpty);
    return parts.isEmpty ? '-' : parts.join(' ');
  }

  /// 지금 draft로 SyncPayload를 만듭니다. 대화 원문 전체가 아니라, 정리된 핵심만 담습니다.
  SyncPayload payload(DraftCommand draft) {
    final category = draft.category!;

    switch (category) {
      case DraftCommandCategory.schedule:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          time: combinedTime(draft),
          location: draft.location,
          alarm: draft.alarm ?? '없음',
          repeat: draft.repeatOption ?? '없음',
          memo: draft.memo ?? '-',
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.health:
        final item = draft.healthItem ?? '';
        final value = draft.title ?? '';
        return SyncPayload(
          category: category.label,
          content: [item, value].where((part) => part.isNotEmpty).join(' : '),
          time: draft.date,
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.memo:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          subType: draft.memoType ?? '일반',
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.project:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          subType: draft.projectAction ?? '생성',
          progress: draft.progress,
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.todo:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
    }
  }
}
