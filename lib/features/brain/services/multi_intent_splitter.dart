// 한 문장 안에 서로 다른 종류의 내용이 여러 개 섞여 있을 수 있습니다. 예:
// "내일 오후 3시에 병원에 가고 매일 30분씩 걷고 우유 사는 것을 메모해줘"
// 이 문장은 (1) 일정, (2) 나의 하루 목표, (3) 메모, 세 가지 서로 다른
// 내용을 담고 있고, 하나로 통째로 저장되면 안 됩니다.
//
// 이 클래스는 다음 순서로 절을 나눕니다.
// ① 쉼표/마침표/줄바꿈, "그리고/그다음/또/하고"(공백으로 둘러싸인 경우)로
//    먼저 나눕니다.
// ② ①에서 나온 절 하나하나에 대해, 쉼표 없이 이어 말한 경우에도 "매일/매주"
//    같은 반복 신호나 "메모해줘/기록해줘/적어줘/기억해줘" 같은 메모 요청
//    신호가 있으면, 그 신호가 속한 절이 실제로 어디서 시작하는지를 앞쪽에서
//    가장 가까운 "-고" 어미(예: "가고 ", "읽고 ")를 기준으로 찾아 그 지점에서
//    나눕니다. 신호가 없으면(=단서가 없으면) 나누지 않습니다 — "병원에 가서
//    검사하고 약도 받아야 해"처럼 신호가 전혀 없는 문장은 절대 쪼개지 않습니다.
//
// 실제 분류(일정/나의 하루 목표/다이어리/메모)는 여기서 하지 않고, 절을
// 나누는 일만 담당합니다 — 분류는 기존 BrainEngine이 절 하나하나에 대해
// 그대로 수행합니다.

class MultiIntentSplitter {
  const MultiIntentSplitter();

  // 쉼표/마침표뿐 아니라 줄바꿈도 절 경계로 봅니다. 사용자가 문장 부호 없이
  // 줄만 바꿔가며 말하는 경우가 많기 때문입니다. "그리고/그다음/또/하고"처럼
  // 앞뒤에 공백을 두고 독립된 단어로 쓰인 연결어도 같은 경계로 봅니다. (앞뒤
  // 공백이 있을 때만 매치하므로 "미팅하고"처럼 동사에 바로 붙은 어미는 건드리지
  // 않습니다)
  static final RegExp _clauseDelimiter = RegExp(
    r'[,、.!\n]+\s*|\s+(?:그리고|그다음|하고|또)\s+',
  );

  // 쉼표가 반복되거나 연결어끼리 붙어 있으면("…가고, 그리고, …") 연결어 하나만
  // 남은 빈 절이 생길 수 있습니다. 실질적인 내용이 없는 이런 절은 카드로 만들지
  // 않고 건너뜁니다.
  static final RegExp _bareConnective = RegExp(r'^(그리고|그다음|하고|또)$');

  // "1시간 전에 알려주고"처럼, 앞 절(주로 일정)의 알림만 덧붙이는 절인지
  // 판단하는 신호입니다. 숫자(또는 한글 수사) + 시간/분 + 전 + 알림 관련 동사가
  // 함께 있어야 합니다.
  static final RegExp _reminderAttachmentPattern = RegExp(
    r'(\d+|한|두|세|네|다섯)\s*(시간|분)\s*전.*?(알려|알림|말해)',
  );

  // "매일/매주/매달"처럼, 나의 하루 목표를 시작하는 강한 반복 신호입니다.
  static final RegExp _repeatCueAnchor = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|매일|매주|매달',
  );

  // "메모해줘/메모해 줘/기록해줘/적어줘/기억해줘/등록해줘"처럼, 메모 절이
  // 끝나는 지점을 알려주는 신호입니다.
  static final RegExp _memoTriggerAnchor = RegExp(
    r'메모해\s*줘|기록해\s*줘|적어\s*줘|기억해\s*줘|등록해\s*줘',
  );

  // 앞 절이 어디서 끝나는지 찾을 때 쓰는 "-고 " 어미 경계입니다. (공백으로
  // 나뉜 한 단어 안에서만 매치되므로 "그리고"처럼 이미 처리된 연결어와
  // 겹치지 않습니다)
  static final RegExp _clauseEndingBoundary = RegExp(r'[가-힣]+고\s+');

  /// 원문을 의미 단위(절)로 나눕니다. 나눌 것이 없으면(절이 하나면) 원문
  /// 그대로 담은 목록 하나를 돌려줍니다.
  List<String> splitClauses(String text) {
    final rawClauses = text
        .split(_clauseDelimiter)
        .map((clause) => clause.trim())
        .where((clause) => clause.isNotEmpty)
        .toList();

    // 쉼표/연결어로 나뉜 절 하나하나에 대해, 그 안에 반복·메모 신호가 더
    // 섞여 있는지 다시 한번 확인합니다(쉼표 없이 이어 말한 부분이 남아 있을
    // 수 있기 때문입니다).
    final expanded = <String>[];
    for (final clause in rawClauses) {
      expanded.addAll(_splitByAnchors(clause));
    }

    if (expanded.isEmpty) return const [];
    if (expanded.length <= 1) return expanded;

    final merged = <String>[];
    for (final clause in expanded) {
      if (_bareConnective.hasMatch(clause)) continue;
      if (merged.isNotEmpty && _reminderAttachmentPattern.hasMatch(clause)) {
        merged[merged.length - 1] = '${merged.last} $clause';
      } else {
        merged.add(clause);
      }
    }
    return merged;
  }

  /// 구분 부호 없이 이어 말한 절 하나 안에서, 반복/메모 신호를 기준으로
  /// 더 나눌 수 있으면 나눕니다. 신호가 없으면(또는 신호는 있어도 그 앞에
  /// 절 경계로 볼 만한 지점이 없으면) 나누지 않고 그대로 돌려줍니다.
  List<String> _splitByAnchors(String text) {
    if (text.isEmpty) return const [];

    final boundaries = <int>{};
    for (final match in _repeatCueAnchor.allMatches(text)) {
      final boundary = _backwardClauseBoundary(text, match.start);
      if (boundary != null) boundaries.add(boundary);
    }
    for (final match in _memoTriggerAnchor.allMatches(text)) {
      final boundary = _backwardClauseBoundary(text, match.start);
      if (boundary != null) boundaries.add(boundary);
    }

    if (boundaries.isEmpty) return [text];

    final sorted = boundaries.toList()..sort();
    final segments = <String>[];
    var start = 0;
    for (final boundary in sorted) {
      if (boundary <= start) continue;
      final piece = text.substring(start, boundary).trim();
      if (piece.isNotEmpty) segments.add(piece);
      start = boundary;
    }
    final last = text.substring(start).trim();
    if (last.isNotEmpty) segments.add(last);

    return segments.isEmpty ? [text] : segments;
  }

  /// [anchorStart] 앞쪽에서 가장 가까운 "-고 " 어미의 끝 위치를 찾습니다.
  /// (그 지점부터가 이 신호가 속한 절의 실제 시작입니다) 찾지 못하면 null —
  /// 이 신호 앞에 더 나눌 절이 없다는 뜻이라 나누지 않습니다.
  int? _backwardClauseBoundary(String text, int anchorStart) {
    final before = text.substring(0, anchorStart);
    Match? last;
    for (final match in _clauseEndingBoundary.allMatches(before)) {
      last = match;
    }
    return last?.end;
  }
}
