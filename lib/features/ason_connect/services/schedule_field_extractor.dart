// 일정 문장에서 날짜·시간·내용을 뽑아냅니다. (장소는 KoreanLocationService에 위임)
// 문장에서 날짜 -> 시간 -> 장소를 차례로 걷어내고, 마지막에 남는 부분을 "내용"으로
// 봅니다. 세 단계가 같은 remaining 문자열을 순서대로 줄여가는 하나의 알고리즘이라
// 날짜/시간 추출과 내용 추출을 억지로 다른 파일로 나누지 않았습니다.

import 'classification_scorer.dart';
import 'korean_location_service.dart';

/// 일정 문장에서 뽑아낸 값들입니다.
class ScheduleExtraction {
  const ScheduleExtraction({
    this.date,
    this.time,
    this.location,
    this.title,
    this.pendingLocationGuess,
    this.pendingLocationOriginal,
  });

  final String? date;
  final String? time;
  final String? location;
  final String? title;

  /// 장소가 확실하지 않을 때, ASON이 되물을 추정 지역명입니다.
  final String? pendingLocationGuess;

  /// 장소가 확실하지 않을 때, 사용자가 실제로 말한 표현입니다.
  final String? pendingLocationOriginal;
}

class ScheduleFieldExtractor {
  ScheduleFieldExtractor({KoreanLocationService? locationService})
    : _locationService = locationService ?? KoreanLocationService();

  final KoreanLocationService _locationService;

  static final RegExp _genericScheduleFiller = RegExp(
    r'^(일정|약속|미팅|회의|모임|출장|방문)?\s*(있어|있다|있음|이야|야)?[.!?]*$',
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

    final timeMatch = ClassificationScorer.timePattern.firstMatch(remaining);
    if (timeMatch != null) {
      time = timeMatch.group(0)!.trim();
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
    }

    final title = remaining
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');

    // "일정 있어"처럼 분류 키워드와 존재 표현만 남은 경우는 실질적인 내용이 아니므로
    // 비어 있는 것으로 보고, 이후 "일정 내용은 무엇인가요?"라고 따로 물어봅니다.
    final isGenericFiller = _genericScheduleFiller.hasMatch(title);

    return ScheduleExtraction(
      date: date,
      time: time,
      location: location,
      title: (title.isEmpty || isGenericFiller) ? null : title,
      pendingLocationGuess: pendingGuess,
      pendingLocationOriginal: pendingOriginal,
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
