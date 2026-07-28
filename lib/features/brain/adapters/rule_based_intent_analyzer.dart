// IntentAnalyzer의 규칙 기반 구현입니다. 기존에 이미 검증된
// CommandParserService.classify()(내부적으로 ClassificationScorer)를 그대로
// 재사용하고, 결과만 IntentResult 모양으로 옮겨 담습니다.

import '../../ason_connect/services/command_parser_service.dart';
import '../models/intent_result.dart';
import '../services/intent_analyzer.dart';

class RuleBasedIntentAnalyzer implements IntentAnalyzer {
  const RuleBasedIntentAnalyzer(this._parser);

  final CommandParserService _parser;

  @override
  IntentResult analyze(String text) {
    final classification = _parser.classify(text);
    return IntentResult(
      category: classification.best,
      confidence: classification.bestScore,
      alternativeCategory: classification.second,
      alternativeConfidence: classification.secondScore,
      isUnclassified: classification.isUnclassified,
      isAmbiguous: classification.isAmbiguous,
    );
  }
}
