// 네 모서리에 작은 HUD 코너 장식이 있는 패널입니다.
// GlowCard보다 가벼운, 입력 영역 등 보조 패널에 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor = AsonColors.primary,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color accentColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AsonColors.surfaceNavy.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: HudCornerOverlay(accentColor: accentColor, child: child),
    );
  }
}

/// 어떤 위젯이든 네 모서리에 작은 HUD 코너 장식을 덧씌워 줍니다.
/// HudPanel, SummaryCard 등에서 공통으로 사용합니다.
class HudCornerOverlay extends StatelessWidget {
  const HudCornerOverlay({
    super.key,
    required this.child,
    this.accentColor = AsonColors.primary,
  });

  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(top: 0, left: 0, child: HudCorner(color: accentColor)),
        Positioned(
          top: 0,
          right: 0,
          child: HudCorner(color: accentColor, flipH: true),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: HudCorner(color: accentColor, flipV: true),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: HudCorner(color: accentColor, flipH: true, flipV: true),
        ),
      ],
    );
  }
}

class HudCorner extends StatelessWidget {
  const HudCorner({
    super.key,
    required this.color,
    this.flipH = false,
    this.flipV = false,
  });

  final Color color;
  final bool flipH;
  final bool flipV;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0, 1.0, 1.0),
      child: CustomPaint(
        size: const Size(14, 14),
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
