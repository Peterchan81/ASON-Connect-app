// Glow 테두리를 두른 반투명 Glass(유리) 카드입니다.
// 배경을 흐리게(blur) 처리해 실제 유리처럼 보이도록 합니다.
// ASON Design System의 모든 카드형 UI(확인 카드, 선택 카드 등)가 이 위젯을 기반으로 합니다.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AsonColors.primary,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
    this.blurSigma = 16,
    this.glowOpacity = 0.3,
    this.borderOpacity = 0.55,
  });

  final Widget child;
  final Color glowColor;
  final double radius;
  final EdgeInsets padding;
  final double blurSigma;
  final double glowOpacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AsonGlow.of(
          glowColor,
          blur: 26,
          opacity: isLight ? glowOpacity * 0.6 : glowOpacity,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isLight
                  ? AsonColors.lightSurface
                  : AsonColors.surfaceNavy.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isLight
                    ? glowColor.withValues(alpha: borderOpacity * 0.7)
                    : glowColor.withValues(alpha: borderOpacity),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
