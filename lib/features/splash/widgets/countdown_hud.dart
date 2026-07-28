// 3→2→1로 줄어드는 큰 원형 카운트다운입니다. 실제로 흐르는 시간에 맞춰 채워집니다.
// 목표 디자인처럼: 세그먼트(대시) 형태의 바깥 링 + 실제 진행 상황을 보여주는
// 얇은 진행 링 + 안쪽의 은은한 광원 + 크고 굵은 숫자로 구성합니다.
// size를 늘리거나 줄이면 모든 구성 요소가 함께 비례해서 커지고 작아집니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class CountdownHud extends StatelessWidget {
  const CountdownHud({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    this.size = 72,
  });

  final int secondsLeft;
  final int totalSeconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds == 0
        ? 0.0
        : (totalSeconds - secondsLeft) / totalSeconds;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 딱딱한 원 테두리 대신, 숫자 뒤에서 은은하게 번지는 광원입니다.
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AsonColors.primary.withValues(alpha: 0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(size: Size(size, size), painter: _CountdownRingPainter()),
          SizedBox(
            width: size * 0.86,
            height: size * 0.86,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size * 0.035,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AsonColors.primary),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              '$secondsLeft',
              key: ValueKey<int>(secondsLeft),
              style: TextStyle(
                fontSize: size * 0.46,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AsonColors.primary.withValues(alpha: 0.85),
                    blurRadius: size * 0.16,
                  ),
                  Shadow(
                    color: AsonColors.primary.withValues(alpha: 0.5),
                    blurRadius: size * 0.32,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 가장 바깥의 옅은 큰 원 + 세그먼트(대시) 형태의 링을 그립니다.
class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    final outerPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.98, outerPaint);

    final dashPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 36;
    for (var i = 0; i < dashCount; i++) {
      if (i % 3 == 0) continue;
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweep = (2 * math.pi / dashCount) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.90),
        startAngle,
        sweep,
        false,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) => false;
}
