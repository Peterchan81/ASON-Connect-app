// ASON-Core(lib/models/memo_model.dart)의 메모 모델을 그대로 옮겨온 것입니다.
// ASON-Core 쪽 주석에도 "AI와 대화 화면에서 저장하는 메모/아이디어도 이 모델과
// 같은 저장 구조를 공유할 수 있도록 범용으로 설계한다"고 되어 있어, ASON Voice의
// Brain Engine 결과도 이 모델 그대로 담아 보냅니다. (필드를 새로 만들지 않고
// ASON-Core의 정의를 그대로 따릅니다)

class MemoModel {
  const MemoModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
    required this.isImportant,
    required this.alarmEnabled,
    this.alarmDateTime,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isImportant;
  final bool alarmEnabled;
  final DateTime? alarmDateTime;

  MemoModel copyWith({
    String? title,
    String? content,
    String? category,
    bool? isImportant,
    bool? alarmEnabled,
    DateTime? alarmDateTime,
    bool clearAlarmDateTime = false,
    DateTime? updatedAt,
  }) {
    return MemoModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate,
      endDate: endDate,
      isImportant: isImportant ?? this.isImportant,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      alarmDateTime: clearAlarmDateTime
          ? null
          : (alarmDateTime ?? this.alarmDateTime),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'isImportant': isImportant,
    'alarmEnabled': alarmEnabled,
    if (alarmDateTime != null)
      'alarmDateTime': alarmDateTime!.toIso8601String(),
  };

  factory MemoModel.fromJson(Map<String, dynamic> json) {
    return MemoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      isImportant: json['isImportant'] as bool,
      alarmEnabled: json['alarmEnabled'] as bool,
      alarmDateTime: json['alarmDateTime'] == null
          ? null
          : DateTime.parse(json['alarmDateTime'] as String),
    );
  }
}
