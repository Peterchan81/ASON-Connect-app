// ASON Voice Service Interface
// 음성 입력 기능을 실제 엔진과 분리해 두는 얇은 추상화 계층입니다. 화면은 이 파일 하나만
// import해서 VoiceService/VoiceState를 사용하고, 엔진 교체는 SpeechProvider 구현체만
// 바꿔서 처리합니다.

export 'mock_speech_provider.dart';
export 'speech_provider.dart';
export 'speech_recognition_provider.dart';
export 'speech_result.dart';
export 'voice_service.dart';
export 'voice_state.dart';
