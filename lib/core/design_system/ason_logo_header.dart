// "ASON" 로고 + "— CONNECT —" 캡션 조합입니다. (Design System 공통 컴포넌트)
// 시작 화면, 로그인 화면, 회원가입 화면이 모두 같은 로고 조합을 공유합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'glow_text.dart';

class AsonLogoHeader extends StatelessWidget {
  const AsonLogoHeader({super.key, this.asonFontSize = 42, this.caption = 'CONNECT'});

  final double asonFontSize;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlowText(
          'ASON',
          style: TextStyle(
            fontSize: asonFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          glowStrength: 1.3,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accentLine(),
            const SizedBox(width: 10),
            Text(
              caption,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: AsonColors.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 10),
            _accentLine(),
          ],
        ),
      ],
    );
  }

  Widget _accentLine() {
    return Container(width: 22, height: 1, color: AsonColors.primary.withValues(alpha: 0.5));
  }
}
