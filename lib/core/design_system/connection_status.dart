// 작은 점 + 문구로 연결 상태를 표시하는 위젯입니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({
    super.key,
    this.label = '연결 준비 완료',
    this.color = AsonColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: AsonGlow.of(color, blur: 8, opacity: 0.9),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
