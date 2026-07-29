// 일정 문장에서 날짜·시간·내용을 뽑아냅니다. (장소는 KoreanLocationService에 위임)
// 문장에서 날짜 -> 시간 -> 장소를 차례로 걷어내고, 마지막에 남는 부분을 "내용"으로
// 봅니다. 세 단계가 같은 remaining 문자열을 순서대로 줄여가는 하나의 알고리즘이라
// 날짜/시간 추출과 내용 추출을 억지로 다른 파일로 나누지 않았습니다.

import 'classification_scorer.dart';
import 'date_expression_parser.dart';
import 'korean_location_service.dart';
import 'title_normalizer.dart';

/// 일정 문장에서 뽑아낸 값들입니다.
class ScheduleExtraction {
  const ScheduleExtraction({
    this.date,
    this.time,
    this.location,
    this.title,
    this.pendingLocationGuess,
    this.pendingLocationOriginal,
    this.alarm,
    this.repeatOption,
  });

  final String? date;
  final String? time;
  final String? location;
  final String? title;

  /// 문장에 직접 포함된 알림 표현입니다. 예: "1시간 전"
  final String? alarm;

  /// 문장에 직접 포함된 반복 표현입니다. 예: "매주 월요일", "없음"
  final String? repeatOption;

  /// 장소가 확실하지 않을 때, ASON이 되물을 추정 지역명입니다.
  final String? pendingLocationGuess;

  /// 장소가 확실하지 않을 때, 사용자가 실제로 말한 표현입니다.
  final String? pendingLocationOriginal;
}

class ScheduleFieldExtractor {
  ScheduleFieldExtractor({
    KoreanLocationService? locationService,
    DateExpressionParser? dateExpressionParser,
  }) : _locationService = locationService ?? KoreanLocationService(),
       _dateExpressionParser = dateExpressionParser ?? DateExpressionParser();

  final KoreanLocationService _locationService;
  final DateExpressionParser _dateExpressionParser;

  // 분류 키워드 하나만 남고 실질적인 내용이 없는 경우입니다. (예: "미팅"만 남음)
  // "광고미팅"처럼 키워드가 다른 단어의 일부이면 실질적인 내용으로 봅니다.
  static final RegExp _bareCategoryWord = RegExp(r'^(일정|약속|미팅|회의|모임|출장|방문)$');

  // "있어/있다/이야"처럼 존재만 나타내는 표현입니다. 실제 내용 뒤에 붙어도
  // ("광고미팅 있어") 내용 자체는 유효하므로, 이 부분만 떼어내고 나머지를
  // 내용으로 씁니다.
  static final RegExp _existentialFillerSuffix = RegExp(r'\s*(있어|있다|있음|이야|야)$');

  // "회의이고"/"확인하며"처럼, 다음 절로 이어지는 연결 어미가 내용 끝에
  // 남아 있으면 떼어냅니다. "-하고"로 끝나는 경우는 여기서 지우지 않고
  // TitleNormalizer가 "-하기" 형태로 자연스럽게 바꿉니다.
  static final RegExp _trailingConnective = RegExp(r'(이고|며)$');

  // "알람 1시간 전", "한 시간 전에 알려주고"처럼 문장에 직접 포함된 알림 표현입니다.
  // 앞의 "알람/알림" 명사와 뒤에 붙는 "알려주고/알려줘" 같은 동사까지 함께 제거해야
  // 내용(title)에 알림 표현이 섞여 들어가지 않습니다.
  static final RegExp _alarmPattern = RegExp(
    r'(알람|알림)?\s*(\d+|한|두|세|네|다섯)\s*(시간|분)\s*전\s*(에)?\s*(알려\S*|알림\S*|말해\S*)?',
  );
  static const Map<String, String> _koreanNumberWords = {
    '한': '1',
    '두': '2',
    '세': '3',
    '네': '4',
    '다섯': '5',
  };

  // "반복 없음"/"반복 없이"처럼 반복이 없음을 명시하는 표현입니다.
  static final RegExp _repeatNonePattern = RegExp(r'반복\s*(없음|없이|안\s*함)');
  // "매일"/"매주 월요일"처럼 반복 주기를 나타내는 표현입니다.
  static final RegExp _repeatPattern = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|매일|매주|매달',
  );

  /// 일정 문장에서 날짜/시간/장소/내용을 최대한 뽑아냅니다.
  ScheduleExtraction extract(String text) {
    String remaining = text;
    String? date;
    String? time;

    const dateWords = ['오늘', '내일', '모레', '어제'];
    for (final word in dateWords) {
      if (remaining.contains(word)) {
        date = word;
        remaining = remaining.replaceFirst(word, ' ');
        break;
      }
    }
    if (date == null) {
      final dateMatch = RegExp(r'\d{1,2}월\s*\d{1,2}일').firstMatch(remaining);
      if (dateMatch != null) {
        date = dateMatch.group(0)!;
        remaining = remaining.replaceFirst(dateMatch.group(0)!, ' ');
      }
    }
    if (date == null) {
      // "다음 주 월요일"/"이번 달 3일"/"금요일" 같은 상대 날짜 표현입니다.
      // 계산에 실패하면(존재하지 않는 날짜 등) 원문을 그대로 둡니다.
      final relativeMatch = _dateExpressionParser.extract(remaining);
      if (relativeMatch != null) {
        date = relativeMatch.formatted;
        remaining = remaining.replaceFirst(relativeMatch.matchedText, ' ');
      }
    }

    final timeMatch = ClassificationScorer.timePattern.firstMatch(remaining);
    if (timeMatch != null) {
      final rawTime = timeMatch.group(0)!.trim();
      // 오전/오후를 말하지 않은 경우, 업무 시간대 회의 표현에 흔한 오후로 간주합니다.
      time = rawTime.startsWith('오전') || rawTime.startsWith('오후')
          ? rawTime
          : '오후 $rawTime';
      remaining = remaining.replaceFirst(timeMatch.group(0)!, ' ');
      // "3시에 둔산동에서"처럼 시간 바로 뒤에 남는 "에" 조사도 함께 정리합니다.
      // ("에서"의 일부까지 지워버리지 않도록 뒤에 "서"가 오면 건드리지 않습니다)
      remaining = remaining.replaceFirst(RegExp(r'^\s*에(?!서)'), ' ');
    }

    final locationResult = _locationService.extractLocation(remaining);
    String? location;
    String? pendingGuess;
    String? pendingOriginal;

    if (locationResult.isConfident) {
      location = locationResult.text;
      remaining = _removeLocationFromRemaining(remaining, location!);
      remaining = remaining.replaceFirst(RegExp(r'^\s*(에서|으로|로)'), ' ');
    } else if (locationResult.isUncertain) {
      pendingGuess = locationResult.uncertainGuess;
      pendingOriginal = locationResult.uncertainOriginal;
    } else {
      // "병원 예약"처럼 장소의 종류만 언급되고 구체적인 이름이 없으면,
      // 나중에 "어느 병원인가요?"라고 따로 물어볼 수 있도록 표시만 해 둡니다.
      pendingOriginal = _locationService.findGenericLandmark(remaining);
    }

    String? alarm;
    final alarmMatch = _alarmPattern.firstMatch(remaining);
    if (alarmMatch != null) {
      final numberWord = alarmMatch.group(2)!;
      final number = _koreanNumberWords[numberWord] ?? numberWord;
      final unit = alarmMatch.group(3)!;
      alarm = '$number$unit 전';
      remaining = remaining.replaceFirst(alarmMatch.group(0)!, ' ');
    }

    String? repeatOption;
    final repeatNoneMatch = _repeatNonePattern.firstMatch(remaining);
    if (repeatNoneMatch != null) {
      repeatOption = '없음';
      remaining = remaining.replaceFirst(repeatNoneMatch.group(0)!, ' ');
    } else {
      final repeatMatch = _repeatPattern.firstMatch(remaining);
      if (repeatMatch != null) {
        repeatOption = repeatMatch.group(0)!.trim();
        remaining = remaining.replaceFirst(repeatMatch.group(0)!, ' ');
      }
    }

    var title = remaining
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');
    title = title.replaceFirst(_existentialFillerSuffix, '').trim();
    title = title.replaceFirst(_trailingConnective, '').trim();

    // "일정 있어"처럼 분류 키워드 하나만 남고 실질적인 내용이 없는 경우는 빈 것으로
    // 보고, 이후 "일정 내용은 무엇인가요?"라고 따로 물어봅니다. "광고미팅"처럼
    // 키워드가 포함된 실제 내용은 그대로 유효한 내용으로 씁니다.
    final isBareCategoryWord = _bareCategoryWord.hasMatch(title);
    final normalizedTitle = title.isEmpty || isBareCategoryWord
        ? null
        : TitleNormalizer.normalizeActionTitle(title);

    return ScheduleExtraction(
      date: date,
      time: time,
      location: location,
      title: normalizedTitle,
      pendingLocationGuess: pendingGuess,
      pendingLocationOriginal: pendingOriginal,
      alarm: alarm,
      repeatOption: repeatOption,
    );
  }

  String _removeLocationFromRemaining(String remaining, String location) {
    if (remaining.contains(location)) {
      return remaining.replaceFirst(location, ' ');
    }
    // 광역 지역명이 자동으로 붙어 원문과 정확히 일치하지 않으면, 마지막 단어 기준으로 제거합니다.
    final lastPart = location.split(' ').last;
    if (remaining.contains(lastPart)) {
      return remaining.replaceFirst(lastPart, ' ');
    }
    return remaining;
  }
}
