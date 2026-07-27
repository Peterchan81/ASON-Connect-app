// 실제 음성 인식 엔진을 감추는 인터페이스입니다.
// 지금은 speech_to_text(기기/브라우저)를 쓰지만, 다음 Sprint 이후 ASON Core 자체 STT나
// 다른 엔진으로 바꾸더라도 VoiceService와 화면 쪽 코드는 이 인터페이스만 보고 동작하므로
// 바뀌지 않습니다. 구현체 예시는 mock_speech_provider.dart(가짜)와
// speech_recognition_provider.dart(features/ason_connect의 실제 서비스를 감싼 어댑터)를
// 참고하세요.

import 'package:flutter/foundation.dart';

import 'speech_result.dart';

abstract class SpeechProvider {
  /// 지금 이 엔진을 사용할 수 있는지 여부입니다. (권한, 플랫폼 지원 여부 등)
  bool get isAvailable;

  /// 지금 듣고 있는 중인지 여부입니다.
  bool get isListening;

  /// 사용 준비를 합니다. (마이크 권한 요청 등) 실패하면 false를 돌려줍니다.
  /// onStatusChange/onError는 엔진이 비동기로 알려주는 상태·오류를 그대로 전달받고
  /// 싶을 때 사용합니다. (예: 듣는 도중 엔진이 스스로 멈추거나 오류가 나는 경우)
  Future<bool> initialize({
    void Function(String status)? onStatusChange,
    void Function(String message, bool permanent)? onError,
  });

  /// 듣기를 시작합니다. 인식 결과(중간/최종)는 onResult로 전달됩니다.
  /// 이미 듣는 중이거나 사용할 수 없으면 false를 돌려줍니다.
  Future<bool> startListening({required ValueChanged<SpeechResult> onResult});

  /// 듣기를 멈춥니다. 멈추는 시점에 마지막 결과가 onResult로 전달될 수 있습니다.
  Future<void> stopListening();

  /// 화면이 사라질 때 호출해서, 사용 중이던 자원을 정리합니다.
  void dispose();
}
