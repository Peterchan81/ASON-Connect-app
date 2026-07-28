// 문장 하나를 읽고 "무엇에 관한 것인가"를 판단하는 인터페이스입니다.
// 이번 Sprint에는 규칙 기반 구현(RuleBasedIntentAnalyzer)만 제공하지만, 이 인터페이스만
// 지키면 향후 OpenAIIntentAnalyzer, GeminiIntentAnalyzer 등으로 교체할 수 있습니다.

import '../models/intent_result.dart';

abstract class IntentAnalyzer {
  IntentResult analyze(String text);
}
