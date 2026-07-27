// 원형 그라디언트 + Glow가 적용된 아바타/아이콘입니다.
// ASON 캐릭터 자리(placeholder), 작은 브랜드 아이콘 등에 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

class GlowAvatar extends StatelessWidget {
  const GlowAvatar({
    super.key,
    this.size = 56,
    this.color = AsonColors.primary,
    this.icon = Icons.auto_awesome,
    this.iconSize,
  });

  final double size;
  final Color color;
  final IconData icon;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: AsonGlow.of(color, blur: size * 0.5, opacity: 0.4),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize ?? size * 0.42),
    );
  }
}
