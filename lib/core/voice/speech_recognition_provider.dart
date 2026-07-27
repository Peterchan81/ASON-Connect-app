// speech_to_text 기반의 실제 SpeechRecognitionService를 SpeechProvider 인터페이스에
// 맞춰주는 어댑터입니다. 이 어댑터가 있어서 VoiceService는 실제 엔진이
// speech_to_text인지, 나중에 다른 엔진인지 몰라도 됩니다.
//
// 지금 단계에서는 화면에 실제로 연결하지 않고(AsonConnectScreen은 기존 방식을 그대로
// 사용합니다), 구조상 교체 가능함을 보여주기 위한 어댑터만 준비해 둡니다.

import 'package:flutter/foundation.dart';

import '../../features/ason_connect/services/speech_recognition_service.dart';
import 'speech_provider.dart';
import 'speech_result.dart';

class SpeechRecognitionProvider implements SpeechProvider {
  SpeechRecognitionProvider({SpeechRecognitionService? service})
    : _service = service ?? SpeechRecognitionService();

  final SpeechRecognitionService _service;

  @override
  bool get isAvailable => _service.isAvailable;

  @override
  bool get isListening => _service.isListening;

  @override
  Future<bool> initialize() {
    // 상세 상태/오류 콜백이 필요하면 다음 Sprint에서 SpeechProvider 인터페이스에
    // 콜백을 추가해 확장할 수 있습니다. 지금은 성공 여부만 필요합니다.
    return _service.initialize(
      onStatusChange: (status) {},
      onError: (message, permanent) {},
    );
  }

  @override
  Future<bool> startListening({required ValueChanged<SpeechResult> onResult}) {
    return _service.startListening(
      onResult: (text, isFinal) =>
          onResult(SpeechResult(text: text, isFinal: isFinal)),
    );
  }

  @override
  Future<void> stopListening() => _service.stopListening();

  @override
  void dispose() => _service.dispose();
}
