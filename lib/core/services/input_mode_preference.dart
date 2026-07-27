// 사용자가 고른 기본 입력 방식(음성/키보드)을 기기에 저장하고 불러오는 서비스입니다.
// 대화 내용은 저장하지 않지만, 이 설정값은 앱을 다시 실행해도 유지되어야 하므로
// SharedPreferences를 사용합니다.

import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/input_mode_selector.dart';

class InputModePreference {
  static const _key = 'ason_input_mode';

  /// 저장된 입력 방식을 불러옵니다. 아직 선택한 적이 없으면 null입니다.
  Future<AsonInputMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    for (final mode in AsonInputMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  /// 선택한 입력 방식을 저장합니다.
  Future<void> save(AsonInputMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
