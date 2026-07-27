// 메모/할 일/프로젝트처럼 문장 전체가 곧 "내용"이 되는 카테고리와, 건강의 증상
// 문구를 가볍게 다듬는 공용 텍스트 정리 유틸리티입니다. 과도하게 문장을 재구성하지
// 않고, 앞뒤 공백·문장 부호 정리와 몇 가지 자연스러운 표현 치환만 합니다.

class ContentNormalizer {
  const ContentNormalizer._();

  /// 문장 전체가 곧 '내용'이 되는 경우, 가볍게 다듬어 돌려줍니다.
  static String cleanFreeform(String text) {
    return text.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  /// 메모/할 일 문장을 짧고 자연스러운 표현으로 가볍게 다듬습니다.
  /// 예: "우유하고 계란 사야 해" -> "우유와 계란 구매"
  static String normalizeMemo(String text) {
    var result = cleanFreeform(text);
    result = result.replaceAll('하고', '와');
    result = result.replaceAll(RegExp(r'사야\s*(해|겠다|함|해요|됨)?'), '구매');
    return result.trim();
  }
}
