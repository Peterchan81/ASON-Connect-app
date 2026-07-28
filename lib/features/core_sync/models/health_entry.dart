// ASON-Core에는 아직 건강 기록 모델/저장소가 없습니다(건강관리 화면은 현재
// PlaceholderScreen). ASON Voice가 이 기능의 기준 모델을 먼저 정의해 두고,
// ASON-Core의 건강관리 화면이 실제로 구현될 때 그대로 재사용할 수 있게 합니다.
// (기존 HomeScheduleEntry/HomeGoalEntry와 같은 형태: id/필드/copyWith/JSON)

class HealthEntry {
  const HealthEntry({
    required this.id,
    required this.item,
    required this.value,
    this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// 항목입니다. 예: "체중", "혈압", "혈당", "운동", "복용", "증상"
  final String item;

  /// 값입니다. 예: "68kg", "128 / 82 mmHg", "혈압약"
  final String value;

  final String? date;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthEntry copyWith({
    String? item,
    String? value,
    String? date,
    DateTime? updatedAt,
  }) {
    return HealthEntry(
      id: id,
      item: item ?? this.item,
      value: value ?? this.value,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': item,
    'value': value,
    if (date != null) 'date': date,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['id'] as String,
      item: json['item'] as String,
      value: json['value'] as String,
      date: json['date'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
