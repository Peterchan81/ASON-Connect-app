// Glow(빛 번짐) 그림자가 적용된 텍스트입니다. 로고/제목처럼 강조가 필요한 곳에 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class GlowText extends StatelessWidget {
  const GlowText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = AsonColors.primary,
    this.glowStrength = 1.0,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowStrength;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        );

    return Text(
      text,
      textAlign: textAlign,
      style: baseStyle.copyWith(
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: 0.85 * glowStrength),
            blurRadius: 18 * glowStrength,
          ),
          Shadow(
            color: glowColor.withValues(alpha: 0.5 * glowStrength),
            blurRadius: 36 * glowStrength,
          ),
        ],
      ),
    );
  }
}
