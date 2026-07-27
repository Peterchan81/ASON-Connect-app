// 음성 인식(Speech-to-Text) 기능을 감싸는 서비스입니다.
// speech_to_text 패키지를 다루는 코드는 모두 이 파일 안에만 둡니다.
// 화면(위젯)은 이 서비스가 콜백으로 알려주는 결과만 받아서 UI 상태를 바꿉니다.

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 인식 중인(또는 최종 확정된) 문장을 화면에 전달할 때 사용하는 콜백입니다.
typedef SpeechResultCallback =
    void Function(String recognizedText, bool isFinal);

/// 음성 인식 상태 변화(듣는 중/중지 등)를 화면에 전달할 때 사용하는 콜백입니다.
typedef SpeechStatusCallback = void Function(String status);

/// 음성 인식 오류를 화면에 전달할 때 사용하는 콜백입니다.
typedef SpeechErrorCallback =
    void Function(String errorMessage, bool permanent);

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // 한국어 인식에 사용할 locale id입니다. 기기에서 사용 가능한지 확인한 뒤 채워집니다.
  String? _koreanLocaleId;
  bool _localeChecked = false;

  /// 지금 음성 인식이 진행 중인지 여부입니다.
  bool get isListening => _speech.isListening;

  /// 마지막 초기화 결과, 지금 이 기기/브라우저에서 음성 인식을 쓸 수 있는지 여부입니다.
  bool get isAvailable => _speech.isAvailable;

  /// 초기화를 진행합니다. 이 과정에서 마이크 권한 확인(필요하면 요청)도 함께 이루어집니다.
  /// 이미 초기화에 성공한 적이 있으면 다시 권한을 묻지 않고 바로 true를 돌려줍니다.
  /// 기기/브라우저가 음성 인식을 지원하지 않거나 권한이 없으면 false를 돌려줍니다.
  Future<bool> initialize({
    required SpeechStatusCallback onStatusChange,
    required SpeechErrorCallback onError,
  }) async {
    bool available;
    try {
      available = await _speech.initialize(
        onStatus: onStatusChange,
        onError: (error) => onError(error.errorMsg, error.permanent),
      );
    } catch (_) {
      // 플랫폼(브라우저 등)이 음성 인식 자체를 지원하지 않는 경우입니다.
      available = false;
    }

    if (available && !_localeChecked) {
      await _resolveKoreanLocale();
    }

    return available;
  }

  /// 음성 인식을 시작합니다.
  /// 이미 듣는 중이거나 사용할 수 없는 상태면 아무 것도 하지 않고 false를 돌려줍니다.
  Future<bool> startListening({required SpeechResultCallback onResult}) async {
    if (_speech.isListening || !_speech.isAvailable) {
      return false;
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          // ko_KR을 우선 사용하고, 확인되지 않았으면(null) 기기의 기본 언어를 사용합니다.
          localeId: _koreanLocaleId,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      // 시작 자체가 실패한 경우입니다. 아래에서 isListening을 확인해 결과를 알려줍니다.
    }

    return _speech.isListening;
  }

  /// 음성 인식을 중지합니다. 중지 직후 마지막 인식 결과가 onResult 콜백으로 전달됩니다.
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// 화면이 사라질 때 호출해서, 진행 중인 음성 인식을 반드시 정리합니다.
  void dispose() {
    if (_speech.isListening) {
      _speech.cancel();
    }
  }

  /// 한국어(ko_KR) 사용 가능 여부를 확인합니다.
  /// 사용할 수 없으면 그냥 넘어가고, 이후 listen에서는 기기의 기본 언어를 사용합니다.
  Future<void> _resolveKoreanLocale() async {
    _localeChecked = true;
    try {
      final locales = await _speech.locales();
      for (final locale in locales) {
        if (locale.localeId == 'ko_KR' ||
            locale.localeId.startsWith('ko_') ||
            locale.localeId.startsWith('ko-')) {
          _koreanLocaleId = locale.localeId;
          return;
        }
      }
    } catch (_) {
      // locale 목록을 가져오지 못해도 기본 언어로 계속 진행합니다.
    }
  }
}
