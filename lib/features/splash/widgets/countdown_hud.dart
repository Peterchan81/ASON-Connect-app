// 3→2→1로 줄어드는 큰 원형 카운트다운입니다. 실제로 흐르는 시간에 맞춰 채워집니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class CountdownHud extends StatelessWidget {
  const CountdownHud({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  final int secondsLeft;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds == 0
        ? 0.0
        : (totalSeconds - secondsLeft) / totalSeconds;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AsonColors.primary),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(secondsLeft),
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AsonColors.primary, width: 1.4),
                boxShadow: AsonGlow.of(
                  AsonColors.primary,
                  blur: 18,
                  opacity: 0.5,
                ),
              ),
              child: Text(
                '$secondsLeft',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
