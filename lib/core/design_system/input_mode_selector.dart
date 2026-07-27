// 사용자가 처음 대화를 시작하기 전, 음성 중심/키보드 중심 중
// 어떤 방식으로 ASON을 사용할지 고르는 선택 UI입니다.
// ASON Voice는 음성 입력이 핵심 기능이므로, 음성 카드를 키보드 카드보다
// 눈에 띄게 크게(약 1.4배) 보여줍니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'glow_card.dart';

/// 사용자가 선택한 기본 입력 방식입니다.
enum AsonInputMode { voice, keyboard }

class InputModeSelector extends StatelessWidget {
  const InputModeSelector({super.key, required this.onSelected});

  final ValueChanged<AsonInputMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '입력 방식을 선택하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _ModeOption(
          icon: Icons.mic_rounded,
          title: '음성 입력',
          description: '말하는 방식으로 ASON을 사용합니다.',
          color: AsonColors.primary,
          emphasized: true,
          onTap: () => onSelected(AsonInputMode.voice),
        ),
        const SizedBox(height: 14),
        _ModeOption(
          icon: Icons.keyboard_alt_outlined,
          title: '키보드 입력',
          description: '입력창에 글자를 써서 ASON을 사용합니다.',
          color: AsonColors.blueNeon,
          emphasized: false,
          onTap: () => onSelected(AsonInputMode.keyboard),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  /// true면 약 1.4배 크게 그려지는 주 카드(음성)입니다.
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = emphasized ? 72.0 : 50.0;
    final iconSize = emphasized ? 34.0 : 24.0;
    final titleSize = emphasized ? 19.0 : 15.0;
    final descriptionSize = emphasized ? 14.0 : 12.5;
    final padding = emphasized
        ? const EdgeInsets.all(22)
        : const EdgeInsets.all(16);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: GlowCard(
        glowColor: color,
        glowOpacity: emphasized ? 0.36 : 0.22,
        padding: padding,
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: descriptionSize,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
