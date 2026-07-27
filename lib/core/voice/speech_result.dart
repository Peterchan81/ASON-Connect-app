// SpeechProvider가 돌려주는 인식 결과 한 건입니다.

class SpeechResult {
  const SpeechResult({required this.text, required this.isFinal});

  /// 지금까지 인식된 문장입니다. isFinal이 false면 계속 바뀔 수 있습니다.
  final String text;

  /// 최종 확정된 결과인지 여부입니다.
  final bool isFinal;
}
