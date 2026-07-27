// SpeechProvider 구현체 하나를 감싸서, 화면이 다루기 쉬운 VoiceState 하나로 정리해 주는
// 서비스입니다. 실제 엔진(SpeechProvider)을 어떤 것으로 교체하더라도 화면 쪽 사용 방식은
// 바뀌지 않습니다.
//
// 지금 단계에서는 화면(AsonConnectScreen)에 실제로 연결하지 않고, 구조와 동작만
// MockSpeechProvider로 검증합니다. 다음 Sprint에서 실제로 교체할 때는
// VoiceService(provider: SpeechRecognitionProvider())처럼 provider만 바꾸면 됩니다.

import 'package:flutter/foundation.dart';

import 'speech_provider.dart';
import 'speech_result.dart';
import 'voice_state.dart';

typedef VoiceResultCallback = void Function(String text, bool isFinal);

class VoiceService {
  // ignore: prefer_initializing_formals
  VoiceService({required SpeechProvider provider}) : _provider = provider;

  final SpeechProvider _provider;

  final ValueNotifier<VoiceState> stateNotifier = ValueNotifier(
    VoiceState.idle,
  );

  VoiceState get state => stateNotifier.value;

  /// 듣고 있지 않으면 듣기를 시작하고, 듣는 중이면 멈춥니다.
  /// 인식 결과는 onResult로, 상태 변화는 stateNotifier로 전달됩니다.
  Future<void> toggle({required VoiceResultCallback onResult}) async {
    if (state == VoiceState.listening) {
      stateNotifier.value = VoiceState.processing;
      await _provider.stopListening();
      return;
    }
    if (state == VoiceState.processing) return;

    final available = _provider.isAvailable || await _provider.initialize();
    if (!available) {
      stateNotifier.value = VoiceState.error;
      return;
    }

    stateNotifier.value = VoiceState.listening;
    final started = await _provider.startListening(
      onResult: (SpeechResult result) {
        onResult(result.text, result.isFinal);
        if (!result.isFinal) return;
        stateNotifier.value = result.text.trim().isEmpty
            ? VoiceState.idle
            : VoiceState.success;
      },
    );

    if (!started) {
      stateNotifier.value = VoiceState.error;
    }
  }

  /// 대기 상태로 되돌립니다. (success 표시가 끝난 뒤 등)
  void reset() => stateNotifier.value = VoiceState.idle;

  void dispose() {
    _provider.dispose();
    stateNotifier.dispose();
  }
}
