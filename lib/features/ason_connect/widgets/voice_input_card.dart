// 음성 입력이 활성화된 상태를 보여주는 카드입니다.
// 큰 마이크 전용 화면 대신, 입력 방식 선택 카드와 같은 자리·같은 크기의
// 카드 안에서 듣는 상태(파형)/처리 중/완료/오류를 표시합니다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/voice_mic_phase.dart';

class VoiceInputCard extends StatelessWidget {
  const VoiceInputCard({
    super.key,
    required this.phase,
    required this.onMicPressed,
  });

  final VoiceMicPhase phase;
  final VoidCallback onMicPressed;

  @override
  Widget build(BuildContext context) {
    final isError = phase == VoiceMicPhase.error;
    final color = isError ? AsonColors.error : AsonColors.primary;

    return InkWell(
      onTap: onMicPressed,
      borderRadius: BorderRadius.circular(22),
      child: GlowCard(
        glowColor: color,
        glowOpacity: 0.28,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
              child: Icon(
                phase == VoiceMicPhase.listening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '음성 입력',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phase.statusText,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (phase == VoiceMicPhase.listening) ...[
              const SizedBox(width: 8),
              _MiniWaveform(color: color),
            ] else
              Icon(
                phase == VoiceMicPhase.processing
                    ? Icons.hourglass_top_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

/// 듣는 중일 때만 보이는 작은 음성 파형입니다.
class _MiniWaveform extends StatefulWidget {
  const _MiniWaveform({required this.color});

  final Color color;

  @override
  State<_MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<_MiniWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

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
        return SizedBox(
          width: 28,
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(4, (index) {
              final phase = index * 0.7;
              final wave =
                  (math.sin(_controller.value * math.pi * 2 + phase) + 1) / 2;
              return Container(
                width: 3,
                height: 6 + 14 * wave,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
