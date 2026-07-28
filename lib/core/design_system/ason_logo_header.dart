// "ASON" 네온 로고 + "— CONNECT —" 캡션 조합입니다. (Design System 공통 컴포넌트)
// 시작 화면, 로그인 화면, 회원가입 화면이 모두 같은 로고 조합을 공유합니다.
//
// ASON 글자는 속이 빈 네온 튜브 형태입니다. (칠해진 두꺼운 글자가 아니라,
// 얇은 그라디언트 외곽선 + 바깥으로 번지는 Glow로 그려집니다)

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
        SizedBox(height: asonFontSize * 0.14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accentLine(),
            SizedBox(width: asonFontSize * 0.18),
            Text(
              caption,
              style: TextStyle(
                fontSize: asonFontSize * 0.28,
                fontWeight: FontWeight.w400,
                letterSpacing: asonFontSize * 0.14,
                color: Colors.white.withValues(alpha: 0.88),
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
      color: AsonColors.primary.withValues(alpha: 0.6),
    );
  }
}

/// 속이 빈 네온 튜브 형태의 "ASON" 워드마크입니다.
/// Paint의 style을 stroke로 두어 글자 외곽선만 그리고, ShaderMask로
/// 위(밝은 노랑/오렌지)->아래(짙은 오렌지) 그라디언트를 입힙니다.
class _NeonAsonWordmark extends StatelessWidget {
  const _NeonAsonWordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final strokeWidth = fontSize * 0.05;
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: fontSize * 0.09,
      height: 1.0,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // 바깥으로 은은하게 번지는 Glow입니다. (굵고 흐린 외곽선)
        Text(
          'ASON',
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 3
              ..color = AsonColors.primary.withValues(alpha: 0.85)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, fontSize * 0.20),
          ),
        ),
        // 글자 속을 아주 옅게 채워, 완전히 뚫린 구멍이 아니라 유리관 속처럼
        // 은은하게 비치는 느낌을 냅니다.
        Text(
          'ASON',
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.fill
              ..color = AsonColors.primary.withValues(alpha: 0.14),
          ),
        ),
        Text(
          'ASON',
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 1.6
              ..color = AsonColors.primary.withValues(alpha: 0.6)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, fontSize * 0.06),
          ),
        ),
        // 얇고 또렷한 네온 외곽선(그라디언트)입니다. 글자 속은 비어 있습니다.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE9B0), Color(0xFFFFA53D), Color(0xFFFF7A00)],
            stops: [0.0, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'ASON',
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..color = Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
