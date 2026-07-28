// Voice Service Interface(VoiceService/SpeechProvider/MockSpeechProvider)가
// 실제 엔진 없이도 올바르게 동작하는지 확인하는 단위 테스트입니다.
// 다음 Sprint에서 실제 엔진(SpeechRecognitionProvider 등)으로 교체해도
// VoiceService의 사용 방식과 상태 흐름은 이 테스트로 계속 보장됩니다.

import 'package:ason_voice_app/core/voice/voice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('대기 상태로 시작한다', () {
    final service = VoiceService(provider: MockSpeechProvider());
    expect(service.state, VoiceState.idle);
    service.dispose();
  });

  test('듣기를 시작하면 listening으로 바뀌고, 인식이 끝나면 success로 바뀐다', () async {
    final service = VoiceService(
      provider: MockSpeechProvider(
        scriptedText: '내일 오후 3시에 미팅',
        respondAfter: const Duration(milliseconds: 10),
      ),
    );

    String? recognized;
    final future = service.toggle(
      onResult: (text, isFinal) {
        if (isFinal) recognized = text;
      },
    );

    expect(service.state, VoiceState.listening);

    await future;
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(recognized, '내일 오후 3시에 미팅');
    expect(service.state, VoiceState.success);

    service.dispose();
  });

  test('엔진을 사용할 수 없으면 error 상태가 된다', () async {
    final service = VoiceService(provider: _UnavailableSpeechProvider());

    await service.toggle(onResult: (text, isFinal) {});

    expect(service.state, VoiceState.error);
    service.dispose();
  });

  test('reset()을 호출하면 idle로 되돌아간다', () async {
    final service = VoiceService(
      provider: MockSpeechProvider(
        scriptedText: '테스트',
        respondAfter: const Duration(milliseconds: 5),
      ),
    );

    await service.toggle(onResult: (text, isFinal) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(service.state, VoiceState.success);

    service.reset();
    expect(service.state, VoiceState.idle);

    service.dispose();
  });
}

/// 권한이 없거나 플랫폼이 지원하지 않는 상황을 흉내 내는 가짜 SpeechProvider입니다.
class _UnavailableSpeechProvider implements SpeechProvider {
  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatusChange,
    void Function(String message, bool permanent)? onError,
  }) async => false;

  @override
  Future<bool> startListening({
    required ValueChanged<SpeechResult> onResult,
  }) async => false;

  @override
  Future<void> stopListening() async {}

  @override
  void dispose() {}
}
