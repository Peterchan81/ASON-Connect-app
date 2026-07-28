// ASON Connect의 앱 설정(테마/알림/언어)을 기기에 저장/불러옵니다.
// 계정과 무관하게 이 기기에서만 적용되는 값입니다.

import 'package:shared_preferences/shared_preferences.dart';

/// 설정 화면에서 고를 수 있는 테마입니다.
/// V1.0은 항상 다크 네온 디자인만 제공하므로, 이 값은 사용자의 선택을
/// 기억해 두는 용도이며 실제 화면 배색을 바꾸지는 않습니다.
enum AppThemeMode {
  dark('다크 모드'),
  light('라이트 모드'),
  system('시스템 설정');

  const AppThemeMode(this.label);
  final String label;
}

/// 앱 언어입니다. 지금은 한국어 하나뿐이지만, 이후 언어가 늘어나도
/// 이 목록에 항목만 추가하면 되도록 구조를 열어둡니다.
enum AppLanguage {
  korean('ko', '한국어(기본)');

  const AppLanguage(this.code, this.label);
  final String code;
  final String label;
}

/// 알림을 받을 수 있는 항목입니다. ASON Connect가 다루는 기능 단위와 맞춥니다.
enum NotificationCategory {
  schedule('일정'),
  memo('메모'),
  health('건강'),
  project('프로젝트');

  const NotificationCategory(this.label);
  final String label;
}

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _kThemeMode = 'ason_settings_theme_mode';
  static const String _kLanguage = 'ason_settings_language';
  static const String _kNotificationPrefix = 'ason_settings_notify_';

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

  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguage);
    return AppLanguage.values.firstWhere(
      (language) => language.code == saved,
      orElse: () => AppLanguage.korean,
    );
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, language.code);
  }

  /// 저장된 값이 없으면 기본값(모두 켜짐)을 돌려줍니다.
  Future<bool> loadNotificationEnabled(NotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kNotificationPrefix${category.name}') ?? true;
  }

  Future<void> saveNotificationEnabled(
    NotificationCategory category,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kNotificationPrefix${category.name}', enabled);
  }
}
