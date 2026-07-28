// 3→2→1로 줄어드는 큰 원형 카운트다운입니다. 실제로 흐르는 시간에 맞춰 채워집니다.
// size를 늘리거나 줄이면 진행 링/안쪽 원/숫자 글씨가 함께 비례해서 커지고 작아집니다.

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
    final innerSize = size * 0.75;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 안쪽 원을 둘러싼 여러 겹의 얇은 네온 링(고정 장식)입니다.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AsonColors.primary.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
          ),
          Container(
            width: size * 0.88,
            height: size * 0.88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AsonColors.primary.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size * 0.042,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AsonColors.primary),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(secondsLeft),
              width: innerSize,
              height: innerSize,
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
                style: TextStyle(
                  fontSize: innerSize * 0.4,
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
