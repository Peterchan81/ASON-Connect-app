// ASON-Core(lib/models/schedule_item.dart의 HomeScheduleEntry, lib/services/
// schedule_service.dart)의 일정 모델을 그대로 옮겨온 것입니다. 필드/JSON 형태를
// 한 글자도 다르지 않게 맞춰서, 두 앱이 같은 기기에서 같은 저장소(SharedPreferences
// 키 `scheduleByDate`)를 공유하게 되었을 때 곧바로 서로의 데이터를 읽고 쓸 수 있게
// 합니다. (두 프로젝트가 하나의 패키지로 합쳐지기 전까지는 이렇게 스키마를
// 동일하게 맞추는 방식으로 "같은 모델을 사용한다"는 요구를 satisfy합니다. 별도의
// 다른 모델을 새로 만드는 것이 아니라, ASON-Core의 모델을 그대로 따르는 것입니다)

class HomeScheduleEntry {
  const HomeScheduleEntry({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.isDone,
    this.memo,
    this.alarmEnabled = false,
  });

  final String id;
  final DateTime date;
  final String time;
  final String title;
  final bool isDone;
  final String? memo;
  final bool alarmEnabled;

  bool get hasTime => time.trim().isNotEmpty && time.trim() != '--:--';

  DateTime? get alarmAt {
    if (!hasTime) return null;
    final parts = time.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  HomeScheduleEntry copyWith({
    DateTime? date,
    String? time,
    String? title,
    bool? isDone,
    String? memo,
    bool? alarmEnabled,
  }) {
    return HomeScheduleEntry(
      id: id,
      date: date ?? this.date,
      time: time ?? this.time,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      memo: memo ?? this.memo,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'title': title,
    'isDone': isDone,
    if (memo != null) 'memo': memo,
    'alarmEnabled': alarmEnabled,
  };

  factory HomeScheduleEntry.fromJson(
    Map<String, dynamic> json, {
    required DateTime date,
  }) {
    return HomeScheduleEntry(
      id: json['id'] as String,
      date: date,
      time: json['time'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
      memo: json['memo'] as String?,
      alarmEnabled: json['alarmEnabled'] as bool? ?? false,
    );
  }
}
