// 대화가 아니라, 정리된 핵심 내용만 담아 ASON Core에 전달하는 데이터입니다.
// 다음 Sprint에서 ASON Core API에 그대로 실어 보낼 수 있도록, 필드 이름과 형태를
// ASON Core 쪽 스키마에 맞춰 정리했습니다. 값이 없는 항목은 null로 둡니다.

class SyncPayload {
  const SyncPayload({
    required this.category,
    required this.content,
    this.time,
    this.location,
    this.alarm,
    this.repeat,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 분류 (한글 라벨, 예: '일정')
  final String category;

  /// 핵심 내용입니다. 예: "김 과장과 미팅", "우유와 계란 구매"
  final String content;

  /// 시간(일정) 또는 날짜(건강) 표현입니다. 예: "오늘 오후 3시"
  final String? time;

  final String? location;

  /// 일정 알림입니다. 예: "30분 전", "없음"
  final String? alarm;

  /// 일정 반복입니다. 예: "매주 월요일", "없음"
  final String? repeat;

  /// 메모입니다. 값이 없으면 "-"입니다.
  final String? memo;

  /// 이 내용이 처음 만들어진 시각입니다.
  final DateTime createdAt;

  /// 이 내용이 마지막으로 수정된 시각입니다.
  final DateTime updatedAt;

  /// ASON Core로 그대로 전송할 수 있는 JSON 형태입니다.
  Map<String, dynamic> toJson() => {
    'category': category,
    'content': content,
    'time': time,
    'location': location,
    'alarm': alarm,
    'repeat': repeat,
    'memo': memo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
