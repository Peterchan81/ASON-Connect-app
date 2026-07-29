// 한 문장 안에 서로 다른 종류의 내용이 여러 개 섞여 있을 수 있습니다. 예:
// "내일 영동에서 3시 광고미팅, 한 시간 전에 알려주고, 매일 아침 스트레칭하기."
// 이 문장은 (1) 일정, (2) 나의 하루 목표, 두 가지 서로 다른 내용을 담고 있고,
// 하나의 일정으로 통째로 저장되면 안 됩니다.
//
// 이 클래스는 쉼표/마침표 등으로 문장을 여러 절로 나눈 뒤, "몇 시간 전에
// 알려줘"처럼 알림만 덧붙이는 절은 새 항목으로 만들지 않고 바로 앞 절에
// 합쳐서(알림 표현으로) 돌려줍니다. 실제 분류(일정/나의 하루 목표/다이어리/메모)는
// 여기서 하지 않고, 절을 나누는 일만 담당합니다 — 분류는 기존 BrainEngine이
// 절 하나하나에 대해 그대로 수행합니다.

class MultiIntentSplitter {
  const MultiIntentSplitter();

  // 쉼표/마침표뿐 아니라 줄바꿈도 절 경계로 봅니다. 사용자가 문장 부호 없이
  // 줄만 바꿔가며 말하는 경우가 많기 때문입니다.
  static final RegExp _clauseDelimiter = RegExp(r'[,、.!\n]+\s*');

  // "1시간 전에 알려주고"처럼, 앞 절(주로 일정)의 알림만 덧붙이는 절인지
  // 판단하는 신호입니다. 숫자(또는 한글 수사) + 시간/분 + 전 + 알림 관련 동사가
  // 함께 있어야 합니다.
  static final RegExp _reminderAttachmentPattern = RegExp(
    r'(\d+|한|두|세|네|다섯)\s*(시간|분)\s*전.*?(알려|알림|말해)',
  );

  // 쉼표/줄바꿈 없이 "-하고" 등으로 이어 말해도, "매일/매주/매달"이 등장하면
  // 그 앞은 다른 내용(주로 일정)이고 그 지점부터는 나의 하루 목표라는 강한
  // 신호로 봅니다. (음성/문자 입력창은 한 줄만 받으므로 쉼표 없이 이어 말하는
  // 경우가 흔합니다)
  static final RegExp _repeatCueAnchor = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|매일|매주|매달',
  );

  /// 원문을 의미 단위(절)로 나눕니다. 나눌 것이 없으면(절이 하나면) 원문
  /// 그대로 담은 목록 하나를 돌려줍니다.
  List<String> splitClauses(String text) {
    final rawClauses = text
        .split(_clauseDelimiter)
        .map((clause) => clause.trim())
        .where((clause) => clause.isNotEmpty)
        .toList();

    final clauses = rawClauses.length <= 1
        ? _splitByRepeatAnchor(text.trim())
        : rawClauses;

    if (clauses.isEmpty) return const [];
    if (clauses.length <= 1) return clauses;

    final merged = <String>[];
    for (final clause in clauses) {
      if (merged.isNotEmpty && _reminderAttachmentPattern.hasMatch(clause)) {
        merged[merged.length - 1] = '${merged.last} $clause';
      } else {
        merged.add(clause);
      }
    }
    return merged;
  }

  /// 구분 부호가 전혀 없는 한 문장 안에서도, "매일/매주/매달"이 문장 중간에
  /// 나타나면 그 지점을 기준으로 앞/뒤 두 절로 나눕니다. 문장 맨 앞에 있으면
  /// (이미 그 자체로 하나의 나의 하루 목표 문장이므로) 나누지 않습니다.
  List<String> _splitByRepeatAnchor(String text) {
    if (text.isEmpty) return const [];
    final match = _repeatCueAnchor.firstMatch(text);
    if (match == null || match.start == 0) return [text];

    final before = text.substring(0, match.start).trim();
    final from = text.substring(match.start).trim();
    if (before.isEmpty || from.isEmpty) return [text];
    return [before, from];
  }
}
