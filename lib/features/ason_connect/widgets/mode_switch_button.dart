// 현재 선택되지 않은 입력 방식으로 즉시 전환할 수 있는 작은 보조 버튼입니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class ModeSwitchButton extends StatelessWidget {
  const ModeSwitchButton({
    super.key,
    required this.toVoice,
    required this.onPressed,
  });

  /// true면 "음성으로 변경"(지금 키보드 모드), false면 "키보드로 변경"(지금 음성 모드) 버튼입니다.
  final bool toVoice;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlowButton(
      label: toVoice ? '음성으로 변경' : '키보드로 변경',
      onPressed: onPressed,
      variant: GlowButtonVariant.text,
      icon: toVoice ? Icons.mic_none_rounded : Icons.keyboard_alt_outlined,
      expand: false,
    );
  }
}
