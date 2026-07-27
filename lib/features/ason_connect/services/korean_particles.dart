// 한글 조사를 받침 유무에 맞게 골라주는 공용 유틸리티입니다.
// ConversationManager(을/를, 으로/로)와 CommandParserService(이/가, 이라고/라고)가
// 각자 따로 구현하던 받침 판별 로직을 이 파일 하나로 모았습니다.

class KoreanParticles {
  const KoreanParticles._();

  /// 마지막 글자에 받침이 있는지 여부입니다. 한글이 아니면 false입니다.
  static bool hasBatchim(String word) {
    if (word.isEmpty) return false;
    final code = word.codeUnitAt(word.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return false;
    return (code - 0xAC00) % 28 != 0;
  }

  /// '으로/로'. 받침이 없거나 'ㄹ' 받침이면 '로'를 씁니다.
  static String euroRo(String word) {
    if (word.isEmpty) return '로';
    final code = word.codeUnitAt(word.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return '로';
    final batchimIndex = (code - 0xAC00) % 28;
    return (batchimIndex == 0 || batchimIndex == 8) ? '로' : '으로';
  }

  /// '을/를'.
  static String eulReul(String word) => hasBatchim(word) ? '을' : '를';

  /// '이/가'.
  static String iGa(String word) => hasBatchim(word) ? '이' : '가';

  /// '이라고/라고'.
  static String iRago(String word) => hasBatchim(word) ? '이라고' : '라고';
}
