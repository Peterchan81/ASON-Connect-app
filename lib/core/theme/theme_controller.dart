// 앱 전체의 테마(다크/라이트/시스템) 상태를 들고 있는 컨트롤러입니다.
// 설정 화면에서 테마를 바꾸면 이 컨트롤러가 notifyListeners()로 알리고,
// MaterialApp(app.dart)이 이를 구독해 즉시 다시 그립니다. 값은
// SettingsService를 통해 SharedPreferences에 저장되어, 앱을 다시 실행해도
// 유지됩니다.

import 'package:flutter/material.dart';

import '../../features/settings/services/settings_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// 앱 시작 시 한 번 호출해 저장된 테마 설정을 불러옵니다.
  Future<void> load() async {
    final saved = await SettingsService.instance.loadThemeMode();
    _themeMode = _toFlutterThemeMode(saved);
    notifyListeners();
  }

  /// 설정 화면에서 테마를 바꿀 때 호출합니다. 저장과 동시에 즉시 반영합니다.
  Future<void> setMode(AppThemeMode mode) async {
    _themeMode = _toFlutterThemeMode(mode);
    notifyListeners();
    await SettingsService.instance.saveThemeMode(mode);
  }

  /// 테스트에서 각 테스트 사이에 상태를 초기화하기 위한 용도입니다.
  void resetForTest() {
    _themeMode = ThemeMode.dark;
  }
}
