// 배경에 은은하게 깔리는 디지털 격자(HUD grid)입니다.
// animate가 true이면 아주 느리게 흐르듯 움직이고, false이면 정지된 상태로 그려집니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class AnimatedHudGrid extends StatefulWidget {
  const AnimatedHudGrid({super.key, this.animate = false, this.spacing = 42});

  final bool animate;
  final double spacing;

  @override
  State<AnimatedHudGrid> createState() => _AnimatedHudGridState();
}

class _AnimatedHudGridState extends State<AnimatedHudGrid>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 26),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return CustomPaint(
        painter: _GridPainter(phase: 0, spacing: widget.spacing),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _GridPainter(
            phase: controller.value,
            spacing: widget.spacing,
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.phase, required this.spacing});

  final double phase;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AsonColors.hudLine.withValues(alpha: 0.32)
      ..strokeWidth = 1;

    final offset = (phase * spacing) % spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (
      double y = -spacing + offset;
      y < size.height + spacing;
      y += spacing
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.spacing != spacing;
}
