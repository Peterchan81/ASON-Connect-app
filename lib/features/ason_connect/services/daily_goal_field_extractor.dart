// "나의 하루 목표" 문장에서 반복 주기와 실제 행동(내용)을 뽑아냅니다.
// 예: "매일 아침 스트레칭하기" -> 반복="매일 아침", 내용="스트레칭"

import 'title_normalizer.dart';

class DailyGoalFieldExtractor {
  const DailyGoalFieldExtractor._();

  static final RegExp _repeatPattern = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|매일|매주|매달',
  );

  static final RegExp _actionSuffix = RegExp(
    r'(하기|하자|해요|합니다|할래|할래요|할거야|할게요|해야지|해야겠다)$',
  );

  /// 문장에서 반복 주기 표현을 찾습니다. 없으면 null입니다.
  static String? extractRepeat(String text) {
    final match = _repeatPattern.firstMatch(text);
    return match?.group(0)?.trim();
  }

  /// 반복 표현과 문장 부호를 걷어내고, 실제 행동만 남긴 내용을 돌려줍니다.
  static String extractTitle(String text, {String? repeat}) {
    var result = text.trim();
    if (repeat != null && repeat.isNotEmpty) {
      result = result.replaceFirst(repeat, '').trim();
    }
    result = result.replaceAll(RegExp(r'[,.!?]+$'), '').trim();
    result = result.replaceFirst(_actionSuffix, '').trim();
    if (result.isEmpty) return result;
    return TitleNormalizer.normalizeActionTitle(result);
  }
}
