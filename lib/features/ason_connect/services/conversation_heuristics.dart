// 분류되지 않은 일반 대화에 자연스럽게 반응하고, 사용자의 짧은 응답이 긍정인지
// 부정인지 판단하는 작은 대화 보조 규칙들입니다. ConversationManager의 흐름 제어와
// 분리해서, "지금 이 말을 어떻게 해석할지"만 담당합니다.

class ConversationHeuristics {
  ConversationHeuristics();

  static const List<String> _moodWords = [
    '기분',
    '힘들',
    '피곤',
    '우울',
    '스트레스',
    '속상',
    '짜증',
    '불안',
    '걱정',
  ];

  static final RegExp _pastActivityPattern = RegExp(
    r'(했어|했다|먹었|갔다|갔어|만났|봤어|봤다|끝났|다녀왔|보냈)',
  );

  static const List<String> _genericRedirects = [
    '저는 사용자의 일정, 메모, 건강에 관한 내용을 정리하고\nASON 통합 시스템에 공유하도록 도와드립니다.',
    '이 내용을 메모로 남기거나 ASON에 공유할 수 있습니다.',
  ];

  static const List<String> _affirmativeWords = [
    '네',
    '응',
    '예',
    '맞아',
    '맞습니다',
    '어',
    'ㅇㅇ',
    '넵',
  ];

  static const List<String> _negativeWords = ['아니', '아니요', '아니에요', 'no', 'No'];

  int _generalReplyIndex = 0;

  /// 일정/메모/건강 중 어디에도 분류되지 않은 문장에 대한 자연스러운 응답입니다.
  String buildGeneralReply(String text) {
    if (_moodWords.any((word) => text.contains(word))) {
      return '오늘 컨디션이 좋지 않으셨군요.\n이 내용을 건강 기록이나 메모로 정리할까요?';
    }
    if (_pastActivityPattern.hasMatch(text)) {
      return '그런 하루를 보내셨군요.\n오늘의 일정이나 메모로 남길까요?';
    }
    final reply =
        _genericRedirects[_generalReplyIndex % _genericRedirects.length];
    _generalReplyIndex++;
    return reply;
  }

  bool isAffirmative(String text) {
    final trimmed = text.trim();
    return _affirmativeWords.any(
      (word) => trimmed == word || trimmed.startsWith(word),
    );
  }

  bool isNegative(String text) {
    final trimmed = text.trim();
    return _negativeWords.any(
      (word) => trimmed == word || trimmed.startsWith(word),
    );
  }
}
