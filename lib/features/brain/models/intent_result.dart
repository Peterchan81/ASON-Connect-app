// IntentAnalyzer가 문장 하나를 읽고 판단한 "이 문장은 무엇에 관한 것인가"의 결과입니다.
// 규칙 기반이든(RuleBasedIntentAnalyzer) 향후 GPT/Gemini 기반이든, 이 모델 하나로
// BrainEngine에 결과를 전달합니다.

import '../../ason_connect/models/draft_command.dart';

class IntentResult {
  const IntentResult({
    required this.category,
    required this.confidence,
    this.alternativeCategory,
    this.alternativeConfidence = 0,
    this.isUnclassified = false,
    this.isAmbiguous = false,
  });

  /// 가장 유력한 카테고리입니다.
  final DraftCommandCategory category;

  /// [category]에 대한 확신도입니다. 값의 범위와 의미는 분석기 구현에 따라 다를 수 있습니다.
  final double confidence;

  /// 애매해서 되물어야 할 때, 그다음으로 유력한 후보입니다.
  final DraftCommandCategory? alternativeCategory;

  /// [alternativeCategory]에 대한 확신도입니다.
  final double alternativeConfidence;

  /// 어떤 카테고리에도 해당하지 않는 일반 대화로 보입니다.
  final bool isUnclassified;

  /// 1·2위 확신도가 비슷해서 사용자에게 되물어야 합니다.
  final bool isAmbiguous;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntentResult &&
          other.category == category &&
          other.confidence == confidence &&
          other.alternativeCategory == alternativeCategory &&
          other.alternativeConfidence == alternativeConfidence &&
          other.isUnclassified == isUnclassified &&
          other.isAmbiguous == isAmbiguous);

  @override
  int get hashCode => Object.hash(
    category,
    confidence,
    alternativeCategory,
    alternativeConfidence,
    isUnclassified,
    isAmbiguous,
  );

  @override
  String toString() =>
      'IntentResult(category: $category, confidence: $confidence, '
      'alternativeCategory: $alternativeCategory, isUnclassified: $isUnclassified, '
      'isAmbiguous: $isAmbiguous)';
}
