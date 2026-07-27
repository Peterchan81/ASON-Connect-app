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
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool animateBackground;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsonColors.darkNavy,
      appBar: appBar,
      body: CyberBackground(
        animate: animateBackground,
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
