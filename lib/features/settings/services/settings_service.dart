// ASON Connect의 앱 설정(테마)을 기기에 저장/불러옵니다.
// 계정과 무관하게 이 기기에서만 적용되는 값입니다.

import 'package:shared_preferences/shared_preferences.dart';

/// 설정 화면(화면 변경)에서 고를 수 있는 테마입니다. 선택하면 ThemeController를
/// 통해 앱 전체(다크/라이트)에 즉시 반영되고, 여기 저장된 값으로 다음 실행에도
/// 유지됩니다.
enum AppThemeMode {
  dark('다크 모드'),
  light('라이트 모드');

  const AppThemeMode(this.label);
  final String label;
}

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _kThemeMode = 'ason_settings_theme_mode';

  Future<AppThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeMode);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => AppThemeMode.dark,
    );
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }
}
