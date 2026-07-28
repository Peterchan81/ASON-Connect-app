// ASON-Core에는 아직 프로젝트 모델/저장소가 없습니다(프로젝트 화면은 현재
// PlaceholderScreen). ASON Voice가 이 기능의 기준 모델을 먼저 정의해 두고,
// ASON-Core의 프로젝트 화면이 실제로 구현될 때 그대로 재사용할 수 있게 합니다.

class ProjectEntry {
  const ProjectEntry({
    required this.id,
    required this.title,
    required this.action,
    this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// 이번 요청이 어떤 활동인지입니다. 예: "생성", "수정", "삭제"
  final String action;

  /// 진행률입니다. 예: "60%"
  final String? progress;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectEntry copyWith({
    String? title,
    String? action,
    String? progress,
    DateTime? updatedAt,
  }) {
    return ProjectEntry(
      id: id,
      title: title ?? this.title,
      action: action ?? this.action,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'action': action,
    if (progress != null) 'progress': progress,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    return ProjectEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      action: json['action'] as String,
      progress: json['progress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
