// ASON Design System의 색상 토큰입니다.
// ASON Voice, ASON Core, 메인/서브/관리자 앱이 모두 공유하는 기준 색상입니다.

import 'package:flutter/material.dart';

class AsonColors {
  AsonColors._();

  /// Primary. 모든 강조 요소(Glow, 버튼, 포인트)에 기본으로 사용합니다.
  static const Color primary = Color(0xFFFF6A00);

  /// Secondary. 사용자 말풍선, 포커스 상태 등 보조 강조에 사용합니다.
  static const Color blueNeon = Color(0xFF00D4FF);

  static const Color darkNavy = Color(0xFF0A0E1A);
  static const Color surfaceNavy = Color(0xFF121A2E);
  static const Color surfaceNavyLight = Color(0xFF1B2438);

  /// 사용자 말풍선 배경입니다. 다른 표면색보다 파란빛이 뚜렷하도록 별도로 둡니다.
  static const Color userBubble = Color(0xFF15304F);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF33D69F);
  static const Color error = Color(0xFFFF5252);

  /// 격자/HUD 선처럼 아주 옅게 쓰는 라인 색상입니다.
  static const Color hudLine = Color(0xFF1E3A5F);

  // ---- 라이트 모드 ----
  // Glow Card/HudPanel/NeonTextField 같은 "떠 있는 어두운 유리" 컴포넌트는
  // 라이트 모드에서도 그대로(다크) 유지합니다. 여기 두 색은 화면 바탕과 상단바처럼
  // 배경 자체가 뒤집혀야 하는 부분에만 사용합니다. ASON Core의 라이트 배색
  // (크림 카드 0xFFFFF7E8, 텍스트 black87/54)과 같은 톤을 재사용합니다.
  static const Color lightBackground = Color(0xFFFBF9F5);
  static const Color lightSurface = Color(0xFFFFF7E8);
  static const Color lightTextPrimary = Color(0xDD000000);
  static const Color lightTextSecondary = Color(0x8A000000);

  /// 화면 배경 위에 바로 놓이는(카드에 감싸이지 않은) 텍스트/아이콘 색입니다.
  /// Glow Card 등 자체적으로 어두운 유리 표면을 가진 컴포넌트 내부에서는
  /// 배경 밝기와 무관하게 항상 밝은 색(Colors.white)을 그대로 사용합니다.
  static Color onBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextPrimary
        : Colors.white;
  }

  static Color onBackgroundMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextSecondary
        : Colors.white.withValues(alpha: 0.7);
  }
}
