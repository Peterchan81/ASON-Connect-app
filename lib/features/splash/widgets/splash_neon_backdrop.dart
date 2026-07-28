// 시작 화면 전용 네온 배경 장식입니다. CyberBackground(격자) 위에 겹쳐서,
// 목표 디자인처럼 모서리 HUD 프레임/입자/회로선(위쪽)과 오렌지 광원+곡선
// 그리드(아래쪽)를 추가로 그립니다. 정적인 CustomPainter로 그려서
// (shouldRepaint=false) 성능 부담이 없습니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// 화면 전체에 겹치는 모서리 HUD 프레임 + 입자 + 회로선입니다.
class SplashNeonBackdrop extends StatelessWidget {
  const SplashNeonBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashScanPainter());
  }
}

class _SplashScanPainter extends CustomPainter {
  const _SplashScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintCornerFrames(canvas, size);
    _paintCircuitLines(canvas, size);
    _paintParticles(canvas, size);
  }

  void _paintCornerFrames(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const armLength = 26.0;
    const margin = 16.0;

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
    corner(
      Offset(margin, size.height - margin),
      const Offset(armLength, 0),
      const Offset(0, -armLength),
    );
    corner(
      Offset(size.width - margin, size.height - margin),
      const Offset(-armLength, 0),
      const Offset(0, -armLength),
    );
  }

  void _paintCircuitLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.14)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.4);

    final topRight = Path()
      ..moveTo(size.width * 0.66, size.height * 0.03)
      ..lineTo(size.width * 0.66, size.height * 0.08)
      ..lineTo(size.width * 0.86, size.height * 0.08);
    canvas.drawPath(topRight, linePaint);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.08),
      2.2,
      nodePaint,
    );

    final topLeft = Path()
      ..moveTo(size.width * 0.10, size.height * 0.05)
      ..lineTo(size.width * 0.24, size.height * 0.05)
      ..lineTo(size.width * 0.24, size.height * 0.10);
    canvas.drawPath(topLeft, linePaint);
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.10),
      2.2,
      nodePaint,
    );
  }

  void _paintParticles(Canvas canvas, Size size) {
    final random = math.Random(7); // 항상 같은 배치가 나오도록 고정 시드를 씁니다.
    final glintPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.55);
    final softGlintPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var i = 0; i < 26; i++) {
      final position = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final isSoft = i % 4 == 0;
      canvas.drawCircle(
        position,
        isSoft ? 1.8 : 1.0,
        isSoft ? softGlintPaint : glintPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashScanPainter oldDelegate) => false;
}

/// 화면 맨 아래에 겹치는 오렌지 광원 + 곡선형 바닥 그리드 + 입자입니다.
class SplashBottomGlow extends StatelessWidget {
  const SplashBottomGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 아래에서 위로 강하게 번지는 빛입니다.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 1.5),
                radius: 1.4,
                colors: [
                  AsonColors.primary.withValues(alpha: 0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _BottomGridPainter())),
        // 화면 하단 중앙의 짧은 네온 라인입니다.
        Positioned(
          left: 56,
          right: 56,
          bottom: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AsonColors.primary.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: AsonGlow.of(
                AsonColors.primary,
                blur: 16,
                opacity: 0.7,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomGridPainter extends CustomPainter {
  const _BottomGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 화면 아래쪽에서 완만하게 휘어지는 얇은 곡선(지평선) 여러 겹입니다.
    final curvePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final dy in [
      size.height * 0.22,
      size.height * 0.42,
      size.height * 0.62,
    ]) {
      final path = Path()
        ..moveTo(0, dy + 16)
        ..quadraticBezierTo(size.width / 2, dy - 16, size.width, dy + 16);
      canvas.drawPath(path, curvePaint);
    }

    // 화면 아래 한 점으로 모이는 얇은 원근 그리드 선입니다.
    final vanishingPoint = Offset(size.width / 2, size.height * 1.7);
    final fanPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (final xFraction in [0.08, 0.28, 0.5, 0.72, 0.92]) {
      canvas.drawLine(
        Offset(size.width * xFraction, size.height),
        vanishingPoint,
        fanPaint,
      );
    }

    final random = math.Random(3);
    final dotPaint = Paint()..color = AsonColors.primary.withValues(alpha: 0.5);
    for (var i = 0; i < 12; i++) {
      final dot = Offset(
        random.nextDouble() * size.width,
        size.height * 0.35 + random.nextDouble() * size.height * 0.65,
      );
      canvas.drawCircle(dot, i % 4 == 0 ? 1.8 : 1.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottomGridPainter oldDelegate) => false;
}
