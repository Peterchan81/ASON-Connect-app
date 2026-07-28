// 시작 화면 전용 네온 배경 장식입니다. CyberBackground(격자/모서리 HUD) 위에
// 겹쳐서, 목표 디자인처럼 중앙 스캔 서클/입자와 하단 광원을 추가로 그립니다.
// 정적인 CustomPainter로 그려서(shouldRepaint=false) 성능 부담이 없습니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// 화면 중앙 위쪽(캐릭터 영역)에 겹치는 스캔 서클 + 입자 + 연결선입니다.
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
    final scanCenter = Offset(size.width / 2, size.height * 0.36);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // 중앙에서 은은하게 번지는 큰 글로우입니다.
    final glowPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(scanCenter, maxRadius * 0.7, glowPaint);

    // 얇은 스캔 서클 여러 겹입니다.
    const ringFractions = [1.0, 0.72, 0.46];
    const ringAlphas = [0.08, 0.06, 0.05];
    for (var i = 0; i < ringFractions.length; i++) {
      final paint = Paint()
        ..color = AsonColors.primary.withValues(alpha: ringAlphas[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(scanCenter, maxRadius * ringFractions[i], paint);
    }

    // 화면 전체에 흩어진 작은 입자 + 몇 개를 잇는 옅은 연결선입니다.
    final random = math.Random(7); // 항상 같은 배치가 나오도록 고정 시드를 씁니다.
    final particles = List<Offset>.generate(16, (i) {
      return Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
    });

    final linePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < particles.length - 1; i += 4) {
      canvas.drawLine(particles[i], particles[i + 1], linePaint);
    }

    final dotPaint = Paint()..color = AsonColors.primary.withValues(alpha: 0.5);
    for (var i = 0; i < particles.length; i++) {
      canvas.drawCircle(particles[i], i % 5 == 0 ? 2.0 : 1.1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashScanPainter oldDelegate) => false;
}

/// 화면 맨 아래에 겹치는 오렌지 광원 + 얇은 곡선 + 입자입니다.
class SplashBottomGlow extends StatelessWidget {
  const SplashBottomGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 아래에서 위로 은은하게 번지는 빛입니다.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 1.4),
                radius: 1.3,
                colors: [
                  AsonColors.primary.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _BottomCurvePainter())),
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
                  AsonColors.primary.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
              boxShadow: AsonGlow.of(AsonColors.primary, blur: 14, opacity: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomCurvePainter extends CustomPainter {
  const _BottomCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final curvePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 화면 아래쪽에서 완만하게 휘어지는 얇은 곡선 두 개입니다. (지평선 느낌)
    for (final dy in [size.height * 0.30, size.height * 0.55]) {
      final path = Path()
        ..moveTo(0, dy + 14)
        ..quadraticBezierTo(size.width / 2, dy - 14, size.width, dy + 14);
      canvas.drawPath(path, curvePaint);
    }

    final random = math.Random(3);
    final dotPaint = Paint()..color = AsonColors.primary.withValues(alpha: 0.45);
    for (var i = 0; i < 10; i++) {
      final dot = Offset(
        random.nextDouble() * size.width,
        size.height * 0.4 + random.nextDouble() * size.height * 0.6,
      );
      canvas.drawCircle(dot, i % 4 == 0 ? 1.8 : 1.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottomCurvePainter oldDelegate) => false;
}
