// 메모로 분류된 문장을 "일반"과 "아이디어"로 한 번 더 가볍게 나눕니다.
// 카테고리 자체(메모/프로젝트/할 일)를 가르는 ClassificationScorer의 키워드와는
// 별개로, 이미 memo로 분류된 문장 안에서만 쓰는 부가 분류입니다.

class MemoClassifier {
  const MemoClassifier._();

  static final RegExp _ideaPattern = RegExp(r'(아이디어|구상|발상|영감|떠올랐|생각나는)');

  /// 메모의 종류입니다. 아이디어를 나타내는 표현이 있으면 "아이디어", 없으면 "일반"입니다.
  static String classify(String text) {
    return _ideaPattern.hasMatch(text) ? '아이디어' : '일반';
  }
}
