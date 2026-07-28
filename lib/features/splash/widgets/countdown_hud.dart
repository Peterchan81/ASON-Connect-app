// 3→2→1로 줄어드는 큰 원형 카운트다운입니다. 실제로 흐르는 시간에 맞춰 채워집니다.
// 목표 디자인처럼: 방사형 눈금 + 배경 링 + 진행 상황을 보여주는 굵은 Glow
// 진행 아크(CustomPainter) + 안쪽 광원 + 속이 빈 네온 숫자로 구성합니다.
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
          // 숫자 뒤에서 은은하게 번지는 광원입니다.
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AsonColors.primary.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _CountdownRingPainter(progress: progress.clamp(0.0, 1.0)),
          ),
          _NeonCountdownNumber(
            key: ValueKey<int>(secondsLeft),
            text: '$secondsLeft',
            size: size,
          ),
        ],
      ),
    );
  }
}

/// 배경 링 + 방사형 눈금 + 세그먼트 링 + 실제 진행 상황을 보여주는 굵은
/// Glow 아크를 그립니다.
class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress});

  final double progress;

  static const _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // 가장 바깥의 옅은 큰 원입니다.
    final outerPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.98, outerPaint);

    // 방사형 눈금입니다.
    final tickPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    const tickCount = 36;
    for (var i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * r * 0.78,
        center + direction * r * 0.90,
        tickPaint,
      );
    }

    // 배경 진행 링(아직 채워지지 않은 부분)입니다.
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r * 0.86, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    if (sweepAngle > 0) {
      // 진행 아크 바깥으로 번지는 Glow입니다.
      final glowPaint = Paint()
        ..color = AsonColors.primary.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.86),
        _startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // 또렷한 진행 아크입니다.
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: const [
            Color(0xFFFFE9B0),
            AsonColors.primary,
            AsonColors.primary,
          ],
          stops: const [0.0, 0.7, 1.0],
          transform: GradientRotation(_startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.86))
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.042
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.86),
        _startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 세그먼트(대시) 형태의 바깥 보조 링입니다.
    final dashPaint = Paint()
      ..color = AsonColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 40;
    for (var i = 0; i < dashCount; i++) {
      if (i % 3 == 0) continue;
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweep = (2 * math.pi / dashCount) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.98),
        startAngle,
        sweep,
        false,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 속이 빈 네온 튜브 형태의 카운트다운 숫자입니다. (ASON 로고와 같은 기법)
class _NeonCountdownNumber extends StatelessWidget {
  const _NeonCountdownNumber({
    super.key,
    required this.text,
    required this.size,
  });

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.46;
    final strokeWidth = fontSize * 0.09;
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Stack(
        key: ValueKey<String>(text),
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth * 3.4
                ..color = AsonColors.primary.withValues(alpha: 0.9)
                ..maskFilter = MaskFilter.blur(
                  BlurStyle.normal,
                  fontSize * 0.22,
                ),
            ),
          ),
          // 숫자 속을 아주 옅게 채워 유리관 속처럼 비치는 느낌을 냅니다.
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = AsonColors.primary.withValues(alpha: 0.16),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE9B0), AsonColors.primary],
            ).createShader(bounds),
            child: Text(
              text,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..color = Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
