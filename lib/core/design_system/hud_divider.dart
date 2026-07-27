// 기본 Material Divider 대신 사용하는, 은은하게 빛나는 가로 구분선입니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class HudDivider extends StatelessWidget {
  const HudDivider({
    super.key,
    this.color = AsonColors.primary,
    this.thickness = 1,
  });

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
