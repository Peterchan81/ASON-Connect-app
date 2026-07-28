// ASON 캐릭터를 감싸는 오렌지 네온 링입니다. (Design System 공통 컴포넌트)
// 목표 디자인처럼: 방사형 스포크 + 여러 겹의 링(외곽/메인 글로우/크리스프/
// 세그먼트) + 좌우 플레어 광원 + 회전하는 Sweep Glow + 외곽 입자로
// 구성합니다.
// 시작 화면, 로그인 화면, 회원가입 화면이 모두 이 위젯을 공유합니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'animated_glow_ring.dart';
import 'ason_colors.dart';
import 'ason_glow.dart';

class CharacterGlow extends StatelessWidget {
  const CharacterGlow({super.key, required this.child, this.size = 260});

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
                blur: size * 0.42,
                opacity: 0.34,
              ),
            ),
          ),
          CustomPaint(size: Size(size, size), painter: _HudCirclePainter()),
          // 메인 링(반지름의 80%)과 같은 크기로 맞춰, 회전하는 밝은 구간이
          // 그 링 위를 따라 도는 것처럼 보이게 합니다.
          AnimatedGlowRing(size: size * 0.8),
          child,
        ],
      ),
    );
  }
}

class _HudCirclePainter extends CustomPainter {
  const _HudCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    _paintSpokes(canvas, center, r);
    _paintRings(canvas, center, r);
    _paintSideFlares(canvas, center, r);
    _paintParticles(canvas, center, r);
  }

  void _paintSpokes(Canvas canvas, Offset center, double r) {
    final spokePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    const spokeCount = 48;
    for (var i = 0; i < spokeCount; i++) {
      final angle = (i / spokeCount) * 2 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * r * 0.52,
        center + direction * r * 0.94,
        spokePaint,
      );
    }
  }

  void _paintRings(Canvas canvas, Offset center, double r) {
    // 가장 바깥의 아주 옅은 큰 원입니다.
    final outerPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.98, outerPaint);

    // 얇은 보조 원입니다.
    final innerFaintPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.60, innerFaintPaint);

    // 굵고 은은하게 번지는 메인 링입니다. (Glow)
    final glowRingPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, r * 0.80, glowRingPaint);

    // 메인 링 위에 겹치는 또렷한 얇은 선입니다.
    final crispRingPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, r * 0.80, crispRingPaint);

    // 세그먼트(대시) 형태의 보조 링입니다. (다이얼처럼 끊어진 느낌)
    final dashPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 54;
    for (var i = 0; i < dashCount; i++) {
      if (i % 3 == 0) continue; // 3칸마다 하나씩 비워 점선처럼 보이게 합니다.
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweep = (2 * math.pi / dashCount) * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.68),
        startAngle,
        sweep,
        false,
        dashPaint,
      );
    }

    // 가장 바깥, 얇고 옅은 두 번째 세그먼트 링입니다.
    final outerDashPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const outerDashCount = 64;
    for (var i = 0; i < outerDashCount; i++) {
      if (i % 4 != 0) continue;
      final startAngle = (i / outerDashCount) * 2 * math.pi;
      const sweep = (2 * math.pi / outerDashCount) * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.90),
        startAngle,
        sweep,
        false,
        outerDashPaint,
      );
    }
  }

  /// 링의 좌우(9시/3시 방향)에서 강하게 번지는 플레어 광원입니다.
  void _paintSideFlares(Canvas canvas, Offset center, double r) {
    final flarePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.10);

    for (final dx in [-r * 0.80, r * 0.80]) {
      canvas.save();
      canvas.translate(center.dx + dx, center.dy);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 0.5, height: r * 0.07),
        flarePaint,
      );
      canvas.restore();
    }
  }

  void _paintParticles(Canvas canvas, Offset center, double r) {
    final random = math.Random(11); // 항상 같은 배치가 나오도록 고정 시드를 씁니다.
    final particlePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.75);
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFE3B8).withValues(alpha: 0.9);

    for (var i = 0; i < 18; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = r * (0.86 + random.nextDouble() * 0.32);
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final isSparkle = i % 6 == 0;
      canvas.drawCircle(
        dot,
        isSparkle ? 2.2 : (random.nextBool() ? 1.8 : 1.0),
        isSparkle ? sparklePaint : particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HudCirclePainter oldDelegate) => false;
}
