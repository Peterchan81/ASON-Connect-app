// 천천히 회전하는 빛의 링입니다. Splash의 캐릭터 링, VoiceOrb의 "생각 중" 표현에 사용합니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class AnimatedGlowRing extends StatefulWidget {
  const AnimatedGlowRing({
    super.key,
    this.size = 200,
    this.color = AsonColors.primary,
    this.secondaryColor = AsonColors.blueNeon,
    this.duration = const Duration(seconds: 7),
    this.rotating = true,
  });

  final double size;
  final Color color;
  final Color secondaryColor;
  final Duration duration;
  final bool rotating;

  @override
  State<AnimatedGlowRing> createState() => _AnimatedGlowRingState();
}

class _AnimatedGlowRingState extends State<AnimatedGlowRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.rotating) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedGlowRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rotating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.rotating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.transparent,
              widget.secondaryColor.withValues(alpha: 0.18),
              widget.color.withValues(alpha: 0.95),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.5, 0.7],
          ),
        ),
      ),
    );
  }
}
