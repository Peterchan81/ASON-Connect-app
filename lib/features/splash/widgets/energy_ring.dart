// ASON 캐릭터를 감싸는 오렌지 에너지 링입니다.
// 여러 겹의 얇은 동심원 + 방사형 눈금 + 회전하는 Sweep Glow를 겹쳐서,
// 캐릭터가 에너지 포털 한가운데 서 있는 듯한 느낌을 만듭니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class EnergyRing extends StatelessWidget {
  const EnergyRing({super.key, required this.child, this.size = 260});

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
                blur: 90,
                opacity: 0.30,
              ),
            ),
          ),
          CustomPaint(size: Size(size, size), painter: _HudCirclePainter()),
          AnimatedGlowRing(size: size * 0.8),
          child,
        ],
      ),
    );
  }
}

/// 여러 겹의 얇은 HUD 동심원 + 외곽 점 + 방사형 눈금을 그립니다.
class _HudCirclePainter extends CustomPainter {
  const _HudCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2 - 2;

    const ringFractions = [1.0, 0.82, 0.64];
    const ringAlphas = [0.30, 0.20, 0.13];
    for (var i = 0; i < ringFractions.length; i++) {
      final paint = Paint()
        ..color = AsonColors.primary.withValues(alpha: ringAlphas[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, maxRadius * ringFractions[i], paint);
    }

    final dotPaint = Paint()..color = AsonColors.primary.withValues(alpha: 0.6);
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final dotCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * maxRadius;
      canvas.drawCircle(dotCenter, i % 3 == 0 ? 2.2 : 1.1, dotPaint);
    }

    // 동/서/남/북 방향의 짧은 눈금입니다. (HUD 다이얼 느낌)
    final tickPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (maxRadius - 7),
        center + direction * (maxRadius + 7),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HudCirclePainter oldDelegate) => false;
}
