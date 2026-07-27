// 실제 마이크/엔진 없이 VoiceService와 화면 로직을 테스트/데모할 수 있도록 만든
// 가짜 SpeechProvider입니다. 브라우저에서 speech_to_text 검증이 제한적인 문제를
// 이 구현으로 우회해서, 음성 관련 상태 전환을 항상 재현 가능하게 테스트할 수 있습니다.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'speech_provider.dart';
import 'speech_result.dart';

class MockSpeechProvider implements SpeechProvider {
  MockSpeechProvider({
    this.scriptedText = '',
    this.respondAfter = const Duration(milliseconds: 300),
  });

  /// 듣기를 시작하면 [respondAfter] 뒤에 이 문장을 최종 인식 결과로 돌려줍니다.
  final String scriptedText;
  final Duration respondAfter;

  bool _isListening = false;
  Timer? _timer;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> startListening({
    required ValueChanged<SpeechResult> onResult,
  }) async {
    if (_isListening) return false;

    _isListening = true;
    _timer?.cancel();
    _timer = Timer(respondAfter, () {
      _isListening = false;
      onResult(SpeechResult(text: scriptedText, isFinal: true));
    });
    return true;
  }

  @override
  Future<void> stopListening() async {
    _timer?.cancel();
    _isListening = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}
