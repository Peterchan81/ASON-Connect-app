// ASON의 시그니처 위젯입니다. 모든 ASON 앱에서 음성 입력의 중심 역할을 합니다.
//
// 상태별 표현:
// - idle: 은은한 Pulse + Orange Glow
// - listening: Ring이 확장되는 듯한 강한 Pulse + Blue Neon + 파형
// - thinking: 회전하는 Glow Ring
// - syncing: 빠르게 반짝이는 Orange Flash
// - success: 체크 아이콘 + 한 번 밝아지는 Glow
// - error: Red Glow(정지)

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'animated_glow_ring.dart';
import 'ason_colors.dart';
import 'ason_glow.dart';

enum VoiceOrbState { idle, listening, thinking, syncing, success, error }

class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.state,
    this.onTap,
    // 요구사항: 터치 가능한 영역 최소 96px, 모바일에서는 120~150px 권장.
    this.size = 128,
  });

  final VoiceOrbState state;
  final VoidCallback? onTap;
  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  // 느린 Pulse(맥동)입니다. idle/listening 상태에서 사용합니다.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  // 동기화 중 빠르게 반짝이는 Flash입니다.
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  // success 상태로 바뀌는 순간 한 번만 밝아지는 Flash입니다.
  late final AnimationController _successController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == VoiceOrbState.success &&
        oldWidget.state != VoiceOrbState.success) {
      _successController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.state) {
      case VoiceOrbState.error:
        return AsonColors.error;
      case VoiceOrbState.listening:
        return AsonColors.blueNeon;
      case VoiceOrbState.success:
        return AsonColors.success;
      case VoiceOrbState.idle:
      case VoiceOrbState.thinking:
      case VoiceOrbState.syncing:
        return AsonColors.primary;
    }
  }

  bool get _isBusy =>
      widget.state == VoiceOrbState.thinking ||
      widget.state == VoiceOrbState.syncing ||
      widget.state == VoiceOrbState.success;

  @override
  Widget build(BuildContext context) {
    final animation = widget.state == VoiceOrbState.syncing
        ? _flashController
        : _pulseController;

    return AnimatedBuilder(
      animation: Listenable.merge([animation, _successController]),
      builder: (context, child) {
        final t = widget.state == VoiceOrbState.thinking
            ? 0.5
            : animation.value;
        final successT = _successController.value;
        final isSuccess = widget.state == VoiceOrbState.success;

        final scale =
            1.0 +
            (widget.state == VoiceOrbState.listening ? 0.18 : 0.08) * t +
            (isSuccess ? 0.12 * (1 - successT) : 0);
        final glowOpacity = isSuccess
            ? 0.75 * (1 - successT) + 0.3
            : (widget.state == VoiceOrbState.listening ? 0.55 : 0.32) *
                  (0.4 + 0.6 * t);

        // 상태가 바뀔 때(예: 대기 오렌지 -> 듣는 중 블루) 색이 뚝 끊기지 않고
        // 부드럽게 번지도록, 실제 색상 표시는 TweenAnimationBuilder를 한 겹 더 거칩니다.
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: _color),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          builder: (context, animatedColor, child) {
            final color = animatedColor ?? _color;

            return SizedBox(
              width: widget.size * 1.5,
              height: widget.size * 1.5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // thinking 상태일 때만 실제로 마운트합니다. (배경에서 불필요하게
                  // 계속 회전하는 애니메이션이 남지 않도록, 사라질 때도 짧게 페이드만 합니다)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: widget.state == VoiceOrbState.thinking
                        ? AnimatedGlowRing(
                            key: const ValueKey('ring'),
                            size: widget.size * 1.3,
                            color: color,
                          )
                        : const SizedBox.shrink(key: ValueKey('no-ring')),
                  ),
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AsonGlow.of(
                          color,
                          blur: 40,
                          spread: 4,
                          opacity: glowOpacity,
                        ),
                      ),
                    ),
                  ),
                  _buildCore(color, t),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCore(Color color, double t) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _isBusy ? null : widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: widget.state == VoiceOrbState.listening
                  ? _buildWaveform(t, key: const ValueKey('waveform'))
                  : Icon(
                      _iconFor(widget.state),
                      key: ValueKey(widget.state),
                      size: widget.size * 0.42,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(VoiceOrbState state) {
    switch (state) {
      case VoiceOrbState.listening:
        return Icons.mic_rounded;
      case VoiceOrbState.thinking:
        return Icons.auto_awesome;
      case VoiceOrbState.syncing:
        return Icons.sync_rounded;
      case VoiceOrbState.success:
        return Icons.check_rounded;
      case VoiceOrbState.error:
        return Icons.priority_high_rounded;
      case VoiceOrbState.idle:
        return Icons.mic_rounded;
    }
  }

  /// 듣는 중일 때 보여주는 작은 음성 파형입니다. 기존 Pulse 애니메이션 값을 그대로 활용합니다.
  Widget _buildWaveform(double t, {Key? key}) {
    final barHeights = List<double>.generate(4, (index) {
      final phase = index * 0.7;
      final wave = (math.sin(t * math.pi * 2 + phase) + 1) / 2;
      return widget.size * (0.16 + 0.22 * wave);
    });

    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final height in barHeights)
          Container(
            width: widget.size * 0.06,
            height: height,
            margin: EdgeInsets.symmetric(horizontal: widget.size * 0.025),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.size * 0.03),
            ),
          ),
      ],
    );
  }
}
