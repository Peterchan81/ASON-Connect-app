// 건강 문장에서 항목(체중/혈압/혈당/운동)과 값을 하나 뽑아냅니다.
// 수치를 찾지 못하면 '증상' 항목으로 문장 자체를 가볍게 정리해서 돌려줍니다.

import 'classification_scorer.dart';
import 'content_normalizer.dart';

/// 건강 문장에서 뽑아낸 항목과 값입니다.
class HealthExtraction {
  const HealthExtraction({this.date, required this.item, required this.value});

  final String? date;
  final String item;
  final String value;
}

class HealthFieldExtractor {
  const HealthFieldExtractor();

  /// 건강 문장에서 항목(체중/혈압/혈당/운동)과 값을 하나 뽑아냅니다.
  /// 수치를 찾지 못하면 '증상' 항목으로 문장 자체를 정리해서 돌려줍니다.
  HealthExtraction extract(String text) {
    String? date;
    const dateWords = ['오늘', '내일', '모레', '어제'];
    for (final word in dateWords) {
      if (text.contains(word)) {
        date = word;
        break;
      }
    }

    final weightMatch = RegExp(
      r'(?:몸무게|체중)[^0-9]{0,5}(\d+(?:\.\d+)?)\s*(?:kg|킬로그램|킬로)?',
    ).firstMatch(text);
    if (weightMatch != null) {
      return HealthExtraction(
        date: date,
        item: '체중',
        value: '${weightMatch.group(1)}kg',
      );
    }

    final bpMatch = RegExp(
      r'혈압[^0-9]{0,5}(\d{2,3})\s*(?:에|/|-)\s*(\d{2,3})',
    ).firstMatch(text);
    if (bpMatch != null) {
      return HealthExtraction(
        date: date,
        item: '혈압',
        value: '${bpMatch.group(1)} / ${bpMatch.group(2)} mmHg',
      );
    }

    final glucoseMatch = RegExp(r'혈당[^0-9]{0,5}(\d+)').firstMatch(text);
    if (glucoseMatch != null) {
      return HealthExtraction(
        date: date,
        item: '혈당',
        value: glucoseMatch.group(1)!,
      );
    }

    final medicationMatch = ClassificationScorer.medicationPattern.firstMatch(
      text,
    );
    if (medicationMatch != null) {
      return HealthExtraction(
        date: date,
        item: '복용',
        value: medicationMatch.group(1)!,
      );
    }

    final exerciseMatch = ClassificationScorer.exercisePattern.firstMatch(text);
    if (exerciseMatch != null) {
      return HealthExtraction(
        date: date,
        item: '운동',
        value: text.substring(exerciseMatch.start, exerciseMatch.end).trim(),
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
