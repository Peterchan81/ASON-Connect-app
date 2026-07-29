// 결과 카드에 보여줄 핵심 내용(제목)을 사람이 말하듯 자연스럽게 다듬습니다.
// 여러 의도로 나뉘기 전 문장은 보통 "~하고/~해서" 같은 연결 어미로 다음
// 절과 이어져 있어서, 그 절만 따로 떼어내면 "병원에 가고"처럼 어색하게
// 남습니다. 이 서비스는 그런 연결 어미를 문장 종결형("~기")으로 바꾸고,
// 메모를 요청하는 동사(메모해줘 등)를 정리해 자연스러운 명사형 제목을
// 만듭니다.
//
// 원칙: 원문 전체를 무리하게 다시 쓰지 않고, 패턴이 맞는 부분만 최소로
// 손댑니다. 어떤 패턴에도 맞지 않으면 원문을 그대로 돌려줍니다(정규화 실패
// 시 원문 유지). 조사 제거는 아주 좁은 목록(을/를/에/씩)만, 그것도 동사
// 바로 앞이 아닌 나머지 단어에서만 보수적으로 처리해 고유명사·사람 이름은
// 건드리지 않습니다(예: "김 부장에게"의 "에게"는 이 목록에 없어 그대로 유지).
class TitleNormalizer {
  const TitleNormalizer._();

  static const List<String> _conservativeParticles = ['을', '를', '에', '씩'];

  /// 일정/나의 하루 목표: 마지막 단어가 "-고"로 끝나면(연결형) "-기"(명사형)로
  /// 바꿉니다. "-고"는 동사 어간에 그대로 붙는 어미라서 "-기"로 바꿔도 어간은
  /// 그대로입니다("가고"→"가기", "걷고"→"걷기", "만나고"→"만나기",
  /// "하고"→"하기"). "-고"로 끝나지 않으면(이미 정리된 문장이면) 손대지
  /// 않습니다.
  static String normalizeActionTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final words = trimmed.split(RegExp(r'\s+'));
    final lastWord = words.last;
    if (lastWord.length < 2 || !lastWord.endsWith('고')) {
      return text;
    }

    words[words.length - 1] = '${lastWord.substring(0, lastWord.length - 1)}기';

    // 동사 앞 단어(들)에 남은 조사는 짧은 제목에서는 보통 생략되므로 걷어냅니다.
    for (var i = 0; i < words.length - 1; i++) {
      final word = words[i];
      for (final particle in _conservativeParticles) {
        if (word.length > particle.length && word.endsWith(particle)) {
          words[i] = word.substring(0, word.length - particle.length);
          break;
        }
      }
    }

    return words.join(' ');
  }

  // "메모해줘"/"메모해 줘"/"기록해줘"/"적어줘"/"기억해줘"/"등록해줘"처럼,
  // 메모를 남겨 달라는 요청 동사입니다.
  static final RegExp _requestVerb = RegExp(
    r'\s*(메모해\s*줘|기록해\s*줘|적어\s*줘|기억해\s*줘|등록해\s*줘)\s*$',
  );

  // "~하는 것을"/"~하는 것"처럼, 앞의 행동을 명사처럼 가리키는 표현입니다.
  static final RegExp _nominalizerSuffix = RegExp(r'\s*것(을)?\s*$');

  // "사야 하는"처럼 "-아/어야 하다"(의무) 형태로 끝나면, 그 의무 표현을
  // 걷어내고 어간만 남깁니다("사야 하는" → 어간 "사").
  static final RegExp _obligationSuffix = RegExp(r'([가-힣]+?)야\s*하는$');

  /// 메모: 요청 동사(메모해줘 등)를 정리하고, 남은 표현을 "~하기" 형태의
  /// 짧은 내용으로 다듬습니다. 요청 동사가 아예 없으면(이미 짧은 메모 내용
  /// 이면) 손대지 않고 원문을 그대로 돌려줍니다.
  static String normalizeMemoRequest(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final withoutRequestVerb = trimmed.replaceFirst(_requestVerb, '').trim();
    if (withoutRequestVerb == trimmed) {
      return text; // 요청 동사가 없으면 정규화 대상이 아닙니다.
    }
    if (withoutRequestVerb.isEmpty) return text;

    var result = withoutRequestVerb.replaceFirst(_nominalizerSuffix, '').trim();
    if (result.isEmpty) return withoutRequestVerb;

    final obligationMatch = _obligationSuffix.firstMatch(result);
    if (obligationMatch != null) {
      final stem = obligationMatch.group(1)!;
      final prefix = result.substring(0, obligationMatch.start);
      result = '$prefix$stem기'.trim();
      return result.isEmpty ? withoutRequestVerb : result;
    }

    if (result.length > 1 && result.endsWith('는')) {
      result = '${result.substring(0, result.length - 1)}기';
    }

    return result;
  }
}
