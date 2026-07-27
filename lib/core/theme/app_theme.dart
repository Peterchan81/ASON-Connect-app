// Flutter MaterialApp에 적용하는 ThemeData입니다.
// 색상 값은 모두 core/design_system/ason_colors.dart(AsonColors)를 기준으로 삼아,
// 디자인 시스템과 항상 같은 팔레트를 사용하도록 합니다.

import 'package:flutter/material.dart';

import '../design_system/ason_colors.dart';

class AppTheme {
  AppTheme._();

  /// 앱 전체에 적용할 어두운 테마입니다.
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AsonColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AsonColors.primary,
          onPrimary: Colors.white,
          secondary: AsonColors.blueNeon,
          onSecondary: AsonColors.darkNavy,
          surface: AsonColors.surfaceNavy,
          onSurface: Colors.white,
          error: AsonColors.error,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AsonColors.darkNavy,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: Colors.white60),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AsonColors.surfaceNavyLight.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AsonColors.blueNeon, width: 1.4),
        ),
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
