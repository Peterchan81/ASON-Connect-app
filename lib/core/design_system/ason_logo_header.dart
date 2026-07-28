// "ASON" 네온 로고 + "— CONNECT —" 캡션 조합입니다. (Design System 공통 컴포넌트)
// 시작 화면, 로그인 화면, 회원가입 화면이 모두 같은 로고 조합을 공유합니다.
//
// ASON 글자는 단순한 흰색 텍스트가 아니라, 위(밝은 오렌지)에서 아래(짙은
// 오렌지/브라운)로 이어지는 그라디언트 + 바깥으로 번지는 Glow를 겹쳐서
// 목표 디자인의 금속/네온 느낌을 냅니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class AsonLogoHeader extends StatelessWidget {
  const AsonLogoHeader({
    super.key,
    this.asonFontSize = 42,
    this.caption = 'CONNECT',
  });

  final double asonFontSize;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NeonAsonWordmark(fontSize: asonFontSize),
        SizedBox(height: asonFontSize * 0.16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accentLine(),
            SizedBox(width: asonFontSize * 0.18),
            Text(
              caption,
              style: TextStyle(
                fontSize: asonFontSize * 0.30,
                fontWeight: FontWeight.w600,
                letterSpacing: asonFontSize * 0.11,
                color: AsonColors.primary.withValues(alpha: 0.92),
              ),
            ),
            SizedBox(width: asonFontSize * 0.18),
            _accentLine(),
          ],
        ),
      ],
    );
  }

  Widget _accentLine() {
    return Container(
      width: asonFontSize * 0.5,
      height: 1,
      color: AsonColors.primary.withValues(alpha: 0.55),
    );
  }
}

/// 위->아래 오렌지 그라디언트 + Glow가 적용된 "ASON" 워드마크입니다.
class _NeonAsonWordmark extends StatelessWidget {
  const _NeonAsonWordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: fontSize * 0.13,
      height: 1.0,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // 바깥으로 은은하게 번지는 Glow(글자 자체는 투명, 그림자만 보입니다).
        Text(
          'ASON',
          style: baseStyle.copyWith(
            color: Colors.transparent,
            shadows: [
              Shadow(
                color: AsonColors.primary.withValues(alpha: 0.95),
                blurRadius: fontSize * 0.75,
              ),
              Shadow(
                color: AsonColors.primary.withValues(alpha: 0.55),
                blurRadius: fontSize * 1.4,
              ),
            ],
          ),
        ),
        // 위(밝은 오렌지)->아래(짙은 오렌지/브라운) 그라디언트가 적용된 글자입니다.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE3B8), Color(0xFFFF9B45), Color(0xFFC85B00)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text('ASON', style: baseStyle.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
