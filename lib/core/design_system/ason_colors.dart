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
}
