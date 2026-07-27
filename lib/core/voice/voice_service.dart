// SpeechProvider 구현체 하나를 감싸서, 화면이 다루기 쉬운 VoiceState 하나로 정리해 주는
// 서비스입니다. 실제 엔진(SpeechProvider)을 어떤 것으로 교체하더라도 화면 쪽 사용 방식은
// 바뀌지 않습니다.
//
// AsonConnectScreen은 VoiceService(provider: SpeechRecognitionProvider())로 실제 엔진에
// 연결하고, 테스트는 MockSpeechProvider로 이 서비스의 상태 전이만 검증합니다.
// 엔진이 비동기로 알려주는 상태 변화(예: 듣는 도중 스스로 멈춤)와 오류도 이 서비스가
// 흡수해서 하나의 VoiceState로만 화면에 전달합니다.

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

    final available =
        _provider.isAvailable ||
        await _provider.initialize(
          onStatusChange: _handleProviderStatus,
          onError: _handleProviderError,
        );
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

  /// 엔진이 스스로 알려주는 상태 변화입니다. 사용자가 멈춤 버튼을 누르지 않아도
  /// 엔진이 알아서 듣기를 멈추는 경우(무음 타임아웃 등), 최종 결과가 오기 전까지
  /// 잠깐 "처리 중" 표시를 보여줍니다.
  void _handleProviderStatus(String status) {
    if (status == 'listening') {
      stateNotifier.value = VoiceState.listening;
      return;
    }
    if ((status == 'notListening' || status == 'done') &&
        state == VoiceState.listening) {
      stateNotifier.value = VoiceState.processing;
    }
  }

  /// 엔진 오류입니다. 오류 메시지 자체는 화면에 노출하지 않고, 오류 상태로만 전환합니다.
  void _handleProviderError(String message, bool permanent) {
    stateNotifier.value = VoiceState.error;
  }

  void dispose() {
    _provider.dispose();
    stateNotifier.dispose();
  }
}
