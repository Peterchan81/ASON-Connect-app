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
  });

  static const empty = EntityResult();

  final String? date;
  final String? time;
  final String? location;
  final String? title;
  final String? healthItem;

  /// 장소가 확실하지 않을 때, ASON이 되물을 추정 지역명입니다.
  final String? pendingLocationGuess;

  /// 장소가 확실하지 않을 때, 사용자가 실제로 말한 표현입니다.
  final String? pendingLocationOriginal;

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
          other.pendingLocationOriginal == pendingLocationOriginal);

  @override
  int get hashCode => Object.hash(
    date,
    time,
    location,
    title,
    healthItem,
    pendingLocationGuess,
    pendingLocationOriginal,
  );

  @override
  String toString() =>
      'EntityResult(date: $date, time: $time, location: $location, '
      'title: $title, healthItem: $healthItem, '
      'pendingLocationGuess: $pendingLocationGuess)';
}
