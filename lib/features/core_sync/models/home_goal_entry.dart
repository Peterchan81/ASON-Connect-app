// ASON-Core(lib/services/goal_service.dart의 HomeGoalEntry)의 "나의 목표 채우기"
// 루틴 모델을 그대로 옮겨온 것입니다. 필드/JSON 형태를 한 글자도 다르지 않게
// 맞춰서, 두 앱이 같은 기기에서 같은 저장소(SharedPreferences 키 `todayGoals`)를
// 공유하게 되었을 때 곧바로 서로의 데이터를 읽고 쓸 수 있게 합니다.

class HomeGoalEntry {
  const HomeGoalEntry({
    required this.id,
    required this.title,
    required this.isDone,
  });

  final String id;
  final String title;
  final bool isDone;

  HomeGoalEntry copyWith({bool? isDone}) {
    return HomeGoalEntry(id: id, title: title, isDone: isDone ?? this.isDone);
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory HomeGoalEntry.fromJson(Map<String, dynamic> json) {
    return HomeGoalEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
    );
  }
}
