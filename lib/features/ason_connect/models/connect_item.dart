// 한 번의 입력에서 여러 개의 의도(일정/나의 하루 목표/다이어리/메모)가 나뉘어
// 나올 때, 항목 하나하나를 화면에 보여주기 위한 가벼운 래퍼입니다. DraftCommand
// 자체에는 "이 항목에 대해 지금 되묻는 질문이 무엇인지"/"동기화 실패 이유"를
// 담을 자리가 없어서(단일 대화 흐름 전용으로 설계됨), 여러 항목을 동시에
// 다루기 위해 이 클래스에 함께 담습니다.

import 'draft_command.dart';

class ConnectItem {
  const ConnectItem({
    required this.draft,
    this.pendingQuestion,
    this.syncError,
  });

  final DraftCommand draft;

  /// 이 항목에 정보가 부족해 되묻는 중일 때 보여줄 질문입니다.
  final String? pendingQuestion;

  /// 이 항목의 마지막 동기화 시도가 실패했다면 그 이유입니다.
  final String? syncError;

  bool get isReady =>
      draft.status == DraftCommandStatus.ready ||
      draft.status == DraftCommandStatus.editing;

  bool get isPending =>
      draft.status == DraftCommandStatus.collecting ||
      draft.status == DraftCommandStatus.clarifyingCategory ||
      draft.status == DraftCommandStatus.editing;

  ConnectItem copyWith({
    DraftCommand? draft,
    String? pendingQuestion,
    bool clearPendingQuestion = false,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return ConnectItem(
      draft: draft ?? this.draft,
      pendingQuestion: clearPendingQuestion
          ? null
          : (pendingQuestion ?? this.pendingQuestion),
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }
}
