// 이번 턴을 어떤 Handler가 처리했는지입니다. BrainResult에 담겨 화면/로그가
// "이번 턴이 어떤 종류의 판단이었는지" 참고할 수 있습니다.

enum BrainTurnType {
  /// 새 주제 입력 (분류 + Entity 추출부터 시작)
  newTopic,

  /// 애매한 분류에 대한 사용자의 선택(카테고리 확인) 응답
  categoryClarification,

  /// 일정 정보 수집 중 후속 답변
  scheduleContinuation,

  /// 메모/건강/프로젝트 등 일정 외 카테고리의 정보 수집 중 후속 답변
  simpleContinuation,

  /// 수정 대화
  editing,

  /// 빈 입력, 미분류, 예외적 입력 등
  fallback,
}
