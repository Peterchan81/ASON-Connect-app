// ASON 캐릭터를 감싸는 오렌지 네온 링입니다. (Design System 공통 컴포넌트)
// 목표 디자인처럼: 굵고 은은하게 번지는 메인 링 + 그 위의 또렷한 얇은 선 +
// 세그먼트(대시) 형태의 보조 링 + 옅은 큰 외곽 원 + 회전하는 Sweep Glow +
// 외곽에 흩어진 작은 입자로 구성합니다.
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
                blur: size * 0.4,
                opacity: 0.32,
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

    // 가장 바깥의 아주 옅은 큰 원입니다.
    final outerPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.98, outerPaint);

    // 굵고 은은하게 번지는 메인 링입니다. (Glow)
    final glowRingPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, r * 0.80, glowRingPaint);

    // 메인 링 위에 겹치는 또렷한 얇은 선입니다.
    final crispRingPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, r * 0.80, crispRingPaint);

    // 세그먼트(대시) 형태의 보조 링입니다. (다이얼처럼 끊어진 느낌)
    final dashPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 48;
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

    // 링 바깥에 흩어진 작은 입자입니다.
    final random = math.Random(11); // 항상 같은 배치가 나오도록 고정 시드를 씁니다.
    final particlePaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.7);
    for (var i = 0; i < 14; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = r * (0.86 + random.nextDouble() * 0.30);
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(dot, random.nextBool() ? 1.8 : 1.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudCirclePainter oldDelegate) => false;
}
