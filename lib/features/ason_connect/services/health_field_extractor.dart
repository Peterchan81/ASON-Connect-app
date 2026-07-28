// 건강 문장에서 항목(체중/혈압/혈당/운동/복용)과 값을 하나 뽑아냅니다.
// 항목은 언급됐지만 수치/이름이 빠져 있으면 value를 null로 돌려주고,
// (ConversationManager가 이어서 "혈압 수치를 알려주세요."처럼 되묻습니다)
// 수치를 찾지 못하면서 항목 키워드도 없으면 '증상' 항목으로 문장 자체를
// 가볍게 정리해서 돌려줍니다.

import 'classification_scorer.dart';
import 'content_normalizer.dart';

/// 건강 문장에서 뽑아낸 항목과 값입니다. [value]가 null이면 항목은 알아냈지만
/// 아직 구체적인 값(수치/이름)을 모른다는 뜻입니다.
class HealthExtraction {
  const HealthExtraction({this.date, required this.item, this.value});

  final String? date;
  final String item;
  final String? value;
}

class HealthFieldExtractor {
  const HealthFieldExtractor();

  static const _weightKeywords = ['몸무게', '체중'];

  /// 건강 문장에서 항목(체중/혈압/혈당/운동/복용)과 값을 하나 뽑아냅니다.
  HealthExtraction extract(String text) {
    String? date;
    const dateWords = ['오늘', '내일', '모레', '어제'];
    for (final word in dateWords) {
      if (text.contains(word)) {
        date = word;
        break;
      }
    }

    // "혈압약 먹었어"처럼 복용 표현은 혈압/체중 키워드보다 먼저 확인합니다.
    // (그렇지 않으면 "혈압약"의 "혈압"이 먼저 걸려 복용이 아닌 수치 질문으로 오인식됩니다)
    final medicationMatch = ClassificationScorer.medicationPattern.firstMatch(
      text,
    );
    if (medicationMatch != null) {
      final name = medicationMatch.group(1)!;
      // "약을 먹었어"처럼 구체적인 이름 없이 "약"만 있으면 되물어야 합니다.
      return HealthExtraction(
        date: date,
        item: '복용',
        value: name == '약' ? null : name,
      );
    }

    if (_weightKeywords.any(text.contains)) {
      final weightMatch = RegExp(
        r'(?:몸무게|체중)[^0-9]{0,5}(\d+(?:\.\d+)?)\s*(?:kg|킬로그램|킬로)?',
      ).firstMatch(text);
      return HealthExtraction(
        date: date,
        item: '체중',
        value: weightMatch == null ? null : '${weightMatch.group(1)}kg',
      );
    }

    if (text.contains('혈압')) {
      final bpMatch = RegExp(
        r'혈압[^0-9]{0,5}(\d{2,3})\s*(?:에|/|-)\s*(\d{2,3})',
      ).firstMatch(text);
      return HealthExtraction(
        date: date,
        item: '혈압',
        value: bpMatch == null
            ? null
            : '${bpMatch.group(1)} / ${bpMatch.group(2)} mmHg',
      );
    }

    if (text.contains('혈당')) {
      final glucoseMatch = RegExp(r'혈당[^0-9]{0,5}(\d+)').firstMatch(text);
      return HealthExtraction(
        date: date,
        item: '혈당',
        value: glucoseMatch?.group(1),
      );
    }

    final exerciseMatch = ClassificationScorer.exercisePattern.firstMatch(text);
    if (exerciseMatch != null || text.contains('운동')) {
      return HealthExtraction(
        date: date,
        item: '운동',
        value: exerciseMatch == null
            ? null
            : text.substring(exerciseMatch.start, exerciseMatch.end).trim(),
      );
    }

    // 수치가 없는 컨디션/증상 표현은 '증상'으로 정리합니다. 의료 진단은 하지 않습니다.
    return HealthExtraction(
      date: date,
      item: '증상',
      value: ContentNormalizer.cleanFreeform(text),
    );
  }
}
