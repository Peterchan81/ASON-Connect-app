// 카카오톡형 대화창에 표시되는 말풍선 하나를 표현하는 모델입니다.

/// 메시지를 보낸 주체입니다.
enum ChatSender {
  user, // 사용자 (오른쪽 말풍선)
  ason, // ASON (왼쪽 말풍선)
}

/// 메시지의 성격입니다. 화면에서 강조 방식을 다르게 하고 싶을 때 사용합니다.
enum ChatMessageType {
  normal, // 일반 대화/안내
  question, // 부족한 정보를 묻는 질문
  summary, // 분석 결과 정리
  syncComplete, // ASON에 공유 완료 안내
  error, // 오류 안내
}

/// 대화창에 표시되는 말풍선 하나의 데이터입니다.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.messageType = ChatMessageType.normal,
  });

  /// 메시지를 구분하기 위한 고유 식별자입니다.
  final String id;

  /// 말풍선에 표시할 문구입니다.
  final String text;

  /// 이 메시지를 보낸 주체입니다.
  final ChatSender sender;

  /// 메시지가 생성된 시각입니다.
  final DateTime createdAt;

  /// 메시지의 성격입니다.
  final ChatMessageType messageType;
}
