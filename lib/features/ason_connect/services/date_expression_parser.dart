// 문장 안의 상대 날짜 표현("다음 주 월요일", "이번 달 3일", "금요일" 등)을 실제
// 달력 날짜로 계산합니다. "오늘/내일/모레/어제"나 "7월 30일" 같은 기존 절대
// 날짜 표현은 ScheduleFieldExtractor가 이미 처리하므로 이 클래스는 다루지
// 않습니다(중복 처리 방지).
//
// 기준 날짜(오늘)는 항상 nowProvider를 통해서만 얻습니다. DateTime.now()를
// 여러 곳에서 직접 부르면 테스트에서 날짜를 고정할 수 없기 때문입니다. 기본값은
// DateTime.now이며, 테스트에서는 고정된 날짜를 돌려주는 함수를 주입합니다.
class DateExpressionMatch {
  const DateExpressionMatch({
    required this.matchedText,
    required this.date,
    required this.formatted,
  });

  /// 원문에서 실제로 찾아낸 표현입니다(뒤따르는 "에"까지 포함될 수 있음).
  /// 제목에서 이 부분만 그대로 잘라내면 됩니다.
  final String matchedText;

  /// 계산된 실제 날짜입니다(시:분:초는 항상 0).
  final DateTime date;

  /// 카드에 보여줄 "YYYY-MM-DD" 형식 문자열입니다.
  final String formatted;
}

class DateExpressionParser {
  DateExpressionParser({DateTime Function()? nowProvider})
    : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;

  static const Map<String, int> _offsetWords = {
    '다다음': 2,
    '이번': 0,
    '다음': 1,
    '지난': -1,
  };

  static const Map<String, int> _weekdayNumbers = {
    '월': DateTime.monday,
    '화': DateTime.tuesday,
    '수': DateTime.wednesday,
    '목': DateTime.thursday,
    '금': DateTime.friday,
    '토': DateTime.saturday,
    '일': DateTime.sunday,
  };

  // "다음 주 월요일"/"다음주 월요일"/"다다음 주 화요일" 등. 뒤에 바로 붙는
  // "에"는 "에서"의 일부가 아닐 때만 함께 매칭해, 제거할 때 따로 처리하지
  // 않아도 되게 합니다.
  static final RegExp _weekPattern = RegExp(
    r'(다다음|이번|다음|지난)\s*주\s*(월|화|수|목|금|토|일)요일(?:\s*에(?!서))?',
  );

  // "다음 달 3일"/"다음달 3일" 등.
  static final RegExp _monthPattern = RegExp(
    r'(다다음|이번|다음|지난)\s*달\s*(\d{1,2})\s*일(?:\s*에(?!서))?',
  );

  // "금요일"처럼 요일만 단독으로 말한 경우입니다. 위 두 패턴이 실패했을 때만
  // 시도하므로 "다음 주 월요일"의 "월요일" 부분과 겹치지 않습니다.
  static final RegExp _weekdayAlonePattern = RegExp(
    r'(월|화|수|목|금|토|일)요일(?:\s*에(?!서))?',
  );

  /// 문장에서 상대 날짜 표현을 찾아 실제 날짜로 계산합니다. 찾지 못했거나
  /// (예: 다음 달에 없는 날짜) 계산이 불가능하면 null을 돌려줍니다 — 이때
  /// 호출한 쪽은 원문을 그대로 유지해야 합니다.
  DateExpressionMatch? extract(String text) {
    final rawNow = _nowProvider();
    final today = DateTime(rawNow.year, rawNow.month, rawNow.day);

    final weekMatch = _weekPattern.firstMatch(text);
    if (weekMatch != null) {
      final offset = _offsetWords[weekMatch.group(1)!]!;
      final weekday = _weekdayNumbers[weekMatch.group(2)!]!;
      final mondayThisWeek = today.subtract(Duration(days: today.weekday - 1));
      final targetMonday = mondayThisWeek.add(Duration(days: offset * 7));
      final target = targetMonday.add(Duration(days: weekday - 1));
      return _matchFor(weekMatch.group(0)!, target);
    }

    final monthMatch = _monthPattern.firstMatch(text);
    if (monthMatch != null) {
      final offset = _offsetWords[monthMatch.group(1)!]!;
      final day = int.parse(monthMatch.group(2)!);
      final totalMonths = (today.year * 12 + (today.month - 1)) + offset;
      final year = totalMonths ~/ 12;
      final month = totalMonths % 12 + 1;
      if (day < 1 || day > _daysInMonth(year, month)) return null;
      return _matchFor(monthMatch.group(0)!, DateTime(year, month, day));
    }

    final weekdayMatch = _weekdayAlonePattern.firstMatch(text);
    if (weekdayMatch != null) {
      final weekday = _weekdayNumbers[weekdayMatch.group(1)!]!;
      var diff = weekday - today.weekday;
      if (diff < 0) diff += 7;
      final target = today.add(Duration(days: diff));
      return _matchFor(weekdayMatch.group(0)!, target);
    }

    return null;
  }

  DateExpressionMatch _matchFor(String matchedText, DateTime date) {
    return DateExpressionMatch(
      matchedText: matchedText,
      date: date,
      formatted:
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  int _daysInMonth(int year, int month) {
    final firstOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }
}
