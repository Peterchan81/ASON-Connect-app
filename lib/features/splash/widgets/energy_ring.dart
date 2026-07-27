// ASON 캐릭터 뒤에서 천천히 회전하는 오렌지 에너지 링 + 얇은 외곽 HUD 원 장식입니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class EnergyRing extends StatelessWidget {
  const EnergyRing({super.key, required this.child, this.size = 210});

  /// 링 중심에 놓일 위젯입니다. (ASON 캐릭터 이미지)
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AsonGlow.of(
                AsonColors.primary,
                blur: 70,
                opacity: 0.32,
              ),
            ),
          ),
          CustomPaint(size: Size(size, size), painter: _HudCirclePainter()),
          AnimatedGlowRing(size: size * 0.86),
          child,
        ],
      ),
    );
  }
}

/// 아주 얇은 외곽 HUD 원과, 그 위에 일정한 간격으로 놓인 작은 점들입니다.
class _HudCirclePainter extends CustomPainter {
  const _HudCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    final circlePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, circlePaint);

    final dotPaint = Paint()..color = AsonColors.primary.withValues(alpha: 0.6);
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * math.pi;
      final dotCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(dotCenter, i % 3 == 0 ? 2.0 : 1.1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudCirclePainter oldDelegate) => false;
}
