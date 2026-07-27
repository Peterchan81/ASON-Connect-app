// 음성 입력 기능의 상태입니다. 어떤 SpeechProvider를 쓰든(디바이스 마이크, 브라우저,
// 추후 ASON Core 자체 STT 등) 화면은 이 값 하나만 보고 UI를 그립니다.

enum VoiceState {
  idle, // 대기: 눌러서 말씀하세요.
  listening, // 듣는 중
  processing, // 인식 결과를 정리하는 중
  success, // 인식 완료
  error, // 사용할 수 없거나 인식 실패
}
