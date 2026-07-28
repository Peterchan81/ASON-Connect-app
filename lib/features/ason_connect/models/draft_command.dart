// 사용자가 지금 전달하고 있는 내용 한 건을 표현하는 모델입니다.
// ConversationManager가 이 객체 하나로 "지금 무엇을 정리하고 있는지" 상태를 관리합니다.
//
// createdAt/updatedAt은 ASON Core와 동기화할 때 그대로 전달되는 시각 정보입니다.
// (다음 Sprint에서 실제 ASON Core와 연결할 때 변경 이력 판단에 사용할 수 있도록 유지합니다)

/// 입력 내용이 어떤 종류로 분류되었는지를 나타냅니다.
enum DraftCommandCategory {
  schedule, // 일정
  memo, // 메모
  health, // 건강
  project, // 프로젝트
  todo, // 할 일
}

/// 화면에 표시할 한글 분류 이름을 반환하는 확장 기능입니다.
extension DraftCommandCategoryLabel on DraftCommandCategory {
  String get label {
    switch (this) {
      case DraftCommandCategory.schedule:
        return '일정';
      case DraftCommandCategory.memo:
        return '메모';
      case DraftCommandCategory.health:
        return '건강';
      case DraftCommandCategory.project:
        return '프로젝트';
      case DraftCommandCategory.todo:
        return '할 일';
    }
  }

  /// 저장이 끝났을 때 자연스럽게 보여줄 완료 문구입니다.
  String get savedMessage {
    switch (this) {
      case DraftCommandCategory.schedule:
        return '일정을 저장했습니다.';
      case DraftCommandCategory.memo:
        return '저장 완료';
      case DraftCommandCategory.health:
        return '건강 기록을 저장했습니다.';
      case DraftCommandCategory.project:
        return '프로젝트를 저장했습니다.';
      case DraftCommandCategory.todo:
        return '할 일을 저장했습니다.';
    }
  }
}

/// 현재 내용이 어느 단계까지 진행되었는지를 나타냅니다.
enum DraftCommandStatus {
  clarifyingCategory, // 분류가 애매해서 사용자에게 되묻는 중
  collecting, // 부족한 정보를 하나씩 질문하며 모으는 중
  ready, // 필요한 정보가 모두 모여서 확인을 기다리는 중
  editing, // 사용자가 수정 버튼을 눌러, 무엇을 바꿀지 되묻는 중 (확인 카드는 계속 보입니다)
  syncing, // ASON 통합 시스템에 동기화하는 중 (가상 처리)
  synced, // 동기화 완료
}

/// 사용자가 지금 전달 중인 내용 하나를 표현하는 데이터 모델입니다.
class DraftCommand {
  DraftCommand({
    required this.originalText,
    required this.status,
    this.category,
    this.candidateCategories = const [],
    this.date,
    this.time,
    this.location,
    this.title,
    this.healthItem,
    this.alarm,
    this.repeatOption,
    this.memo,
    this.pendingLocationGuess,
    this.pendingLocationOriginal,
    this.memoType,
    this.projectAction,
    this.progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// 사용자가 이 주제를 처음 꺼낸 원본 문장입니다. (동기화 대상에는 포함되지 않습니다)
  final String originalText;

  /// 현재 진행 상태입니다.
  final DraftCommandStatus status;

  /// 분류된 카테고리입니다. 분류가 애매해서 되묻는 중에는 null입니다.
  final DraftCommandCategory? category;

  /// 분류가 애매할 때, ASON이 사용자에게 제시한 후보 카테고리 목록입니다.
  final List<DraftCommandCategory> candidateCategories;

  /// 날짜 (일정·건강에서 사용)
  final String? date;

  /// 시간 (일정에서 사용)
  final String? time;

  /// 장소 (일정에서 사용)
  final String? location;

  /// 내용 (일정·메모·프로젝트·할 일의 내용, 건강의 수치/값)
  final String? title;

  /// 건강 항목 이름입니다. 예: "혈압", "체중", "혈당", "운동", "증상"
  final String? healthItem;

  /// 일정 알림입니다. 예: "30분 전", "없음"
  final String? alarm;

  /// 일정 반복입니다. 예: "매주 월요일", "없음". 대화 중 먼저 묻지 않고, 수정 대화에서만 채웁니다.
  final String? repeatOption;

  /// 일정 메모입니다. 대화 중 먼저 묻지 않고, 수정 대화에서만 채웁니다.
  final String? memo;

  /// 장소가 불확실할 때, ASON이 추정한 정식 지역명입니다. (예: "대전 둔산동")
  final String? pendingLocationGuess;

  /// 장소가 불확실할 때, 사용자가 실제로 말한 표현입니다. (예: "둔산")
  final String? pendingLocationOriginal;

  /// 메모의 종류입니다. (memo 카테고리에서만 사용) 예: "일반", "아이디어"
  final String? memoType;

  /// 프로젝트에 대해 하려는 활동입니다. (project 카테고리에서만 사용) 예: "생성", "수정", "삭제"
  final String? projectAction;

  /// 프로젝트 진행률입니다. (project 카테고리에서만 사용) 예: "60%"
  final String? progress;

  /// 이 내용을 처음 만든 시각입니다. copyWith로도 바뀌지 않습니다.
  final DateTime createdAt;

  /// 이 내용을 마지막으로 고친 시각입니다. copyWith할 때마다 새로 갱신됩니다.
  final DateTime updatedAt;

  /// 일부 값만 바꾼 새로운 DraftCommand를 만듭니다. updatedAt은 항상 지금 시각으로 갱신됩니다.
  DraftCommand copyWith({
    DraftCommandStatus? status,
    DraftCommandCategory? category,
    List<DraftCommandCategory>? candidateCategories,
    String? date,
    String? time,
    String? location,
    String? title,
    String? healthItem,
    String? alarm,
    String? repeatOption,
    String? memo,
    String? pendingLocationGuess,
    String? pendingLocationOriginal,
    String? memoType,
    String? projectAction,
    String? progress,
    bool clearPendingLocation = false,
  }) {
    return DraftCommand(
      originalText: originalText,
      status: status ?? this.status,
      category: category ?? this.category,
      candidateCategories: candidateCategories ?? this.candidateCategories,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      title: title ?? this.title,
      healthItem: healthItem ?? this.healthItem,
      alarm: alarm ?? this.alarm,
      repeatOption: repeatOption ?? this.repeatOption,
      memo: memo ?? this.memo,
      pendingLocationGuess: clearPendingLocation
          ? null
          : (pendingLocationGuess ?? this.pendingLocationGuess),
      pendingLocationOriginal: clearPendingLocation
          ? null
          : (pendingLocationOriginal ?? this.pendingLocationOriginal),
      memoType: memoType ?? this.memoType,
      projectAction: projectAction ?? this.projectAction,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
