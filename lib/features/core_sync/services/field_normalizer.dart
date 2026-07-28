// 필드 타입별 정규화 유틸리티입니다. 사용자의 원문(Draft/채팅 메시지)은
// 항상 그대로 보존하고, 이 클래스는 "정규화된 값"만 별도로 계산해 돌려줍니다.
// (원문 자체를 고치거나 지우지 않습니다)
//
// 날짜/시간 정규화 로직은 원래 CoreSyncMapper 안에만 있던 것을 그대로 옮겨온
// 것입니다(동작 변경 없음). 여러 곳(동기화 저장, 실시간 미리보기 패널, 중복
// 확인)에서 같은 정규화 결과를 재사용하기 위해 공용 유틸리티로 분리했습니다.

class FieldNormalizer {
  FieldNormalizer._();

  /// "내일"/"오늘"처럼 상대적인 한글 표현이나 "8월 15일" 형식을 실제 날짜로
  /// 바꿉니다. 알 수 없으면 오늘 날짜를 씁니다.
  static DateTime resolveDate(String? koreanDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (koreanDate) {
      case '오늘':
        return today;
      case '내일':
        return today.add(const Duration(days: 1));
      case '모레':
        return today.add(const Duration(days: 2));
      case '어제':
        return today.subtract(const Duration(days: 1));
    }
    if (koreanDate != null) {
      final match = RegExp(r'(\d{1,2})월\s*(\d{1,2})일').firstMatch(koreanDate);
      if (match != null) {
        final month = int.parse(match.group(1)!);
        final day = int.parse(match.group(2)!);
        return DateTime(today.year, month, day);
      }
    }
    return today;
  }

  /// "오후 3시"/"오전 10시 30분" 같은 한글 시간 표현을 "HH:mm" 24시간 형식으로
  /// 바꿉니다. 알 수 없으면 "--:--"(시간 없음)입니다.
  static String normalizeTime(String? koreanTime) {
    if (koreanTime == null) return '--:--';
    final match = RegExp(
      r'(오전|오후)?\s*(\d{1,2})시\s*(\d{1,2})?분?',
    ).firstMatch(koreanTime);
    if (match == null) return '--:--';

    var hour = int.tryParse(match.group(2) ?? '') ?? 0;
    final minute = int.tryParse(match.group(3) ?? '') ?? 0;
    final isPm = match.group(1) == '오후';
    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 전화번호처럼 숫자만 필요한 필드에서, 섞여 들어간 문자/구분 기호를 걷어내고
  /// 숫자만 뽑아냅니다. 예: "12df34tsd56" -> "123456"
  /// 일정 제목/메모처럼 원문 의미가 중요한 필드에는 사용하지 않습니다.
  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');
}
