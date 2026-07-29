// 아직 아무것도 입력하지 않은 첫 화면에서 보여주는, 크고 명확한 두 개의
// 선택 버튼입니다. 종류(일정/메모 등)를 고르는 것이 아니라, "음성으로
// 말할지" "문자로 입력할지"만 고르는 화면이며, 하나를 누르면 곧바로 그
// 방식의 입력이 시작됩니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class InputModeStartSelector extends StatelessWidget {
  const InputModeStartSelector({
    super.key,
    required this.onSelectVoice,
    required this.onSelectKeyboard,
  });

  final VoidCallback onSelectVoice;
  final VoidCallback onSelectKeyboard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StartModeButton(
              icon: Icons.mic_rounded,
              label: '음성으로 말하기',
              glowColor: AsonColors.blueNeon,
              onPressed: onSelectVoice,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StartModeButton(
              icon: Icons.keyboard_alt_outlined,
              label: '문자로 입력하기',
              glowColor: AsonColors.primary,
              onPressed: onSelectKeyboard,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartModeButton extends StatelessWidget {
  const _StartModeButton({
    required this.icon,
    required this.label,
    required this.glowColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color glowColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      radius: 18,
      glowColor: glowColor,
      glowOpacity: 0.28,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: glowColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AsonColors.onBackground(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
