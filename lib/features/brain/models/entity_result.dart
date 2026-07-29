// EntityAnalyzer가 문장에서 뽑아낸 값들입니다. 카테고리마다 실제로 쓰는 필드가
// 다르므로(일정: date/time/location/title, 건강: date/healthItem/title 등)
// DraftCommand와 같은 모양의 선택적 필드를 모두 담을 수 있게 설계했습니다.

class EntityResult {
  const EntityResult({
    this.date,
    this.time,
    this.location,
    this.title,
    this.healthItem,
    this.pendingLocationGuess,
    this.pendingLocationOriginal,
    this.memoType,
    this.projectAction,
    this.progress,
    this.alarm,
    this.repeatOption,
  });

  static const empty = EntityResult();

  final String? date;
  final String? time;
  final String? location;
  final String? title;
  final String? healthItem;

  /// 일정 알림입니다. (일정 문장에 직접 포함된 경우에만 채워집니다) 예: "1시간 전"
  final String? alarm;

  /// 반복입니다. 일정의 반복 또는 나의 하루 목표의 반복 주기입니다. 예: "매일 아침", "없음"
  final String? repeatOption;

  /// 장소가 확실하지 않을 때, ASON이 되물을 추정 지역명입니다.
  final String? pendingLocationGuess;

  /// 장소가 확실하지 않을 때, 사용자가 실제로 말한 표현입니다.
  final String? pendingLocationOriginal;

  /// 메모의 종류입니다. (memo 카테고리에서만 사용) 예: "일반", "아이디어"
  final String? memoType;

  /// 프로젝트에 대해 하려는 활동입니다. (project 카테고리에서만 사용) 예: "생성", "수정", "삭제"
  final String? projectAction;

  /// 프로젝트 진행률입니다. (project 카테고리에서만 사용) 예: "60%"
  final String? progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityResult &&
          other.date == date &&
          other.time == time &&
          other.location == location &&
          other.title == title &&
          other.healthItem == healthItem &&
          other.pendingLocationGuess == pendingLocationGuess &&
          other.pendingLocationOriginal == pendingLocationOriginal &&
          other.memoType == memoType &&
          other.projectAction == projectAction &&
          other.progress == progress &&
          other.alarm == alarm &&
          other.repeatOption == repeatOption);

  @override
  int get hashCode => Object.hash(
    date,
    time,
    location,
    title,
    healthItem,
    pendingLocationGuess,
    pendingLocationOriginal,
    memoType,
    projectAction,
    progress,
    alarm,
    repeatOption,
  );

  @override
  String toString() =>
      'EntityResult(date: $date, time: $time, location: $location, '
      'title: $title, healthItem: $healthItem, '
      'pendingLocationGuess: $pendingLocationGuess, memoType: $memoType, '
      'projectAction: $projectAction, progress: $progress, alarm: $alarm, '
      'repeatOption: $repeatOption)';
}
