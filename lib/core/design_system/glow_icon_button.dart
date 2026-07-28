// ASON Design System의 원형 아이콘 버튼입니다. 전송 버튼, 보조 토글 버튼 등에 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

class GlowIconButton extends StatelessWidget {
  const GlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.color = AsonColors.primary,
    this.filled = true,
    this.glow = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final bool filled;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final unfilledTint = isLight
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.06);
    final unfilledIconColor = isLight
        ? AsonColors.lightTextSecondary
        : Colors.white70;

    final button = Material(
      color: filled ? color : unfilledTint,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.42,
            color: filled ? Colors.white : unfilledIconColor,
          ),
        ),
      ),
    );

    if (!glow || !filled) return button;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AsonGlow.of(color, blur: 16, opacity: 0.45),
      ),
      child: button,
    );
  }
}
