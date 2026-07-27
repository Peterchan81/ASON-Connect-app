// Glow(빛 번짐) 그림자를 만드는 공용 헬퍼입니다.
// ASON Design System 전체에서 이 함수 하나로 Glow 표현을 통일합니다.

import 'package:flutter/material.dart';

class AsonGlow {
  AsonGlow._();

  static List<BoxShadow> of(
    Color color, {
    double blur = 24,
    double spread = 0,
    double opacity = 0.5,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
