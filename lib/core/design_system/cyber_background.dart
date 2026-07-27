// ASON 화면 배경입니다. Dark Navy 위에 얇은 격자, 일부만 보이는 회로선, 작은 빛나는 점,
// 모서리 HUD 장식, 하단 빛의 지평선을 겹쳐서 표현합니다.
// 단순한 단색 배경 대신, 모든 화면에서 이 위젯으로 배경을 통일합니다.
//
// 성능을 위해 회로선/점/모서리 장식은 정적인 CustomPainter 하나로 그리고
// (shouldRepaint=false), 격자만 필요할 때 아주 느리게 움직입니다.

import 'package:flutter/material.dart';

import 'animated_grid.dart';
import 'ason_colors.dart';

class CyberBackground extends StatelessWidget {
  const CyberBackground({super.key, this.animate = false, this.child});

  final bool animate;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AsonColors.darkNavy),
        Positioned.fill(child: AnimatedHudGrid(animate: animate)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _CyberDetailsPainter()),
          ),
        ),
        // 좌상단에서 은은하게 번지는 오렌지 글로우입니다.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.8),
                  radius: 1.2,
                  colors: [
                    AsonColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // 하단 빛의 지평선 효과입니다.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AsonColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

/// 회로선, 접점, 작은 빛나는 점, 화면 모서리 HUD 장식을 그리는 정적인 페인터입니다.
/// 내용은 매 프레임 바뀌지 않으므로 shouldRepaint를 false로 두어 성능을 지킵니다.
class _CyberDetailsPainter extends CustomPainter {
  const _CyberDetailsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintCircuitLines(canvas, size);
    _paintDots(canvas, size);
    _paintCorners(canvas, size);
  }

  void _paintCircuitLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.13)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.36);

    final topRight = Path()
      ..moveTo(size.width * 0.62, 0)
      ..lineTo(size.width * 0.62, size.height * 0.06)
      ..lineTo(size.width * 0.84, size.height * 0.06)
      ..lineTo(size.width * 0.84, size.height * 0.14)
      ..lineTo(size.width, size.height * 0.14);
    canvas.drawPath(topRight, linePaint);
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.14),
      2.4,
      nodePaint,
    );

    final bottomLeft = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.16, size.height * 0.82)
      ..lineTo(size.width * 0.16, size.height * 0.92)
      ..lineTo(size.width * 0.36, size.height * 0.92);
    canvas.drawPath(bottomLeft, linePaint);
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.82),
      2.4,
      nodePaint,
    );
  }

  void _paintDots(Canvas canvas, Size size) {
    final dotPositions = [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.34),
      Offset(size.width * 0.22, size.height * 0.64),
      Offset(size.width * 0.74, size.height * 0.78),
      Offset(size.width * 0.46, size.height * 0.09),
    ];
    final glowPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final position in dotPositions) {
      canvas.drawCircle(position, 1.6, glowPaint);
    }
  }

  void _paintCorners(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.22)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const armLength = 22.0;
    const margin = 14.0;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    corner(
      const Offset(margin, margin),
      const Offset(armLength, 0),
      const Offset(0, armLength),
    );
    corner(
      Offset(size.width - margin, margin),
      const Offset(-armLength, 0),
      const Offset(0, armLength),
    );
  }

  @override
  bool shouldRepaint(covariant _CyberDetailsPainter oldDelegate) => false;
}
