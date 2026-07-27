// 기본 Material AppBar 대신 사용하는 ASON 전용 상단바입니다.
// 그림자·리플 등 기본 Material 느낌 없이, 제목/부제/우측 상태를 직접 그립니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';

class CyberTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CyberTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AsonColors.darkNavy.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(color: AsonColors.primary.withValues(alpha: 0.28)),
        ),
        boxShadow: [
          BoxShadow(
            color: AsonColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            ?leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
