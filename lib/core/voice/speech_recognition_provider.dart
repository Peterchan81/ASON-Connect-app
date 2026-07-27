// speech_to_text 기반의 실제 SpeechRecognitionService를 SpeechProvider 인터페이스에
// 맞춰주는 어댑터입니다. 이 어댑터가 있어서 VoiceService는 실제 엔진이
// speech_to_text인지, 나중에 다른 엔진인지 몰라도 됩니다.
//
// AsonConnectScreen이 실제로 사용하는 프로덕션 어댑터입니다.
// (VoiceService(provider: SpeechRecognitionProvider())로 연결됩니다)

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
  Future<bool> initialize({
    void Function(String status)? onStatusChange,
    void Function(String message, bool permanent)? onError,
  }) {
    return _service.initialize(
      onStatusChange: onStatusChange ?? (status) {},
      onError: onError ?? (message, permanent) {},
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
