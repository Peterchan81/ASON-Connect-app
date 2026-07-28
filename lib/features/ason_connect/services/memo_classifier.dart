// 메모로 분류된 문장을 "일반"과 "아이디어"로 한 번 더 가볍게 나눕니다.
// 카테고리 자체(메모/프로젝트/할 일)를 가르는 ClassificationScorer의 키워드와는
// 별개로, 이미 memo로 분류된 문장 안에서만 쓰는 부가 분류입니다.

class MemoClassifier {
  const MemoClassifier._();

  static final RegExp _ideaPattern = RegExp(r'(아이디어|구상|발상|영감|떠올랐|생각나는)');

  // "좋은 아이디어가 있어"처럼 메모하고 싶다는 의사만 있고 실제 내용이 없는 문장입니다.
  static final RegExp _genericFillerPattern = RegExp(
    r'^(좋은\s*|괜찮은\s*)?(아이디어|생각|메모|기록)(가|이)?\s*'
    r'(있어|있다|있음|있네|생겼어|떠올랐어|났어)[.!?]*$',
  );

  /// 메모의 종류입니다. 아이디어를 나타내는 표현이 있으면 "아이디어", 없으면 "일반"입니다.
  static String classify(String text) {
    return _ideaPattern.hasMatch(text) ? '아이디어' : '일반';
  }

  /// 실제 메모 내용 없이 "메모할 게 있다"는 의사만 밝힌 문장인지 여부입니다.
  static bool isGenericFiller(String text) {
    return _genericFillerPattern.hasMatch(text.trim());
  }
}
