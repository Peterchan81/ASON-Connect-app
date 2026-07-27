// 음성 인식(SpeechRecognitionService)의 진행 상태입니다.
// 화면에서는 이 값을 core/design_system의 VoiceOrbState로 변환해서 그립니다.

enum VoiceMicPhase {
  ready, // 준비: 눌러서 말씀하세요.
  listening, // 듣는 중: 듣고 있습니다.
  processing, // 처리 중: 내용을 정리하고 있습니다.
  success, // 인식 완료: 짧게 한 번 밝아지는 표시 후 ready로 돌아갑니다.
  error, // 오류: 음성을 인식하지 못했습니다.
}

extension VoiceMicPhaseLabel on VoiceMicPhase {
  String get statusText {
    switch (this) {
      case VoiceMicPhase.ready:
        return '눌러서 말씀하세요.';
      case VoiceMicPhase.listening:
        return '듣고 있습니다.';
      case VoiceMicPhase.processing:
        return '내용을 정리하고 있습니다.';
      case VoiceMicPhase.success:
        return '내용을 전달했습니다.';
      case VoiceMicPhase.error:
        return '음성을 인식하지 못했습니다.\n다시 말씀해 주세요.';
    }
  }
}
