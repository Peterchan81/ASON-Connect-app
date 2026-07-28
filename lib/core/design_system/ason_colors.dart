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
  // 밝은 회색/아이보리 배경 위에 흰색 카드, 진한 회색 기본 글자·회색 보조
  // 글자, 오렌지(primary) 포인트를 그대로 사용합니다. GlowCard/HudPanel/
  // NeonTextField 등 모든 디자인 시스템 컴포넌트가 Theme.of(context).brightness를
  // 보고 이 팔레트로 전환됩니다.
  static const Color lightBackground = Color(0xFFF2F0EB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF2D2D2D);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  /// 화면 배경(또는 카드) 위에 놓이는 기본 텍스트/아이콘 색입니다. 다크
  /// 모드에서는 흰색, 라이트 모드에서는 진한 회색을 사용해 대비를 지킵니다.
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
