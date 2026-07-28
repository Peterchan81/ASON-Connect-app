// ASON 화면의 공통 뼈대입니다. Dark Navy 배경 + CyberBackground + 최대 폭 제한을
// 한 번에 적용해서, 모든 화면이 같은 틀 위에서 만들어지도록 합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'cyber_background.dart';

class CyberScaffold extends StatelessWidget {
  const CyberScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.animateBackground = false,
    this.maxWidth = 600,
    this.forceDark = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool animateBackground;
  final double maxWidth;

  /// true면 앱 테마 설정과 무관하게 항상 다크 네온으로 그립니다.
  /// Splash/로그인/회원가입처럼 브랜드 인트로 성격이 강한 화면에서 사용합니다.
  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    final isLight =
        !forceDark && Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight
          ? AsonColors.lightBackground
          : AsonColors.darkNavy,
      appBar: appBar,
      body: CyberBackground(
        animate: animateBackground,
        forceDark: forceDark,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}
