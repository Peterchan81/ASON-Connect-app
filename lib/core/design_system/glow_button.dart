// ASON Design System의 기본 버튼입니다. 기본 Material 버튼 대신 이 위젯을 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

enum GlowButtonVariant { filled, outline, text, dark }

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlowButtonVariant.filled,
    this.color = AsonColors.primary,
    this.icon,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlowButtonVariant variant;
  final Color color;
  final IconData? icon;
  final bool expand;

  /// true면 라벨 대신 작은 로딩 표시를 보여주고, 중복 클릭을 막기 위해
  /// onPressed가 눌려도 무시합니다. (예: 로그인/동기화 처리 중)
  final bool isLoading;

  bool get _isDisabled => onPressed == null || isLoading;

  Color get _background {
    switch (variant) {
      case GlowButtonVariant.filled:
        return _isDisabled ? color.withValues(alpha: 0.3) : color;
      case GlowButtonVariant.dark:
        return AsonColors.surfaceNavyLight;
      case GlowButtonVariant.outline:
      case GlowButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color get _foreground {
    switch (variant) {
      case GlowButtonVariant.filled:
        return Colors.white;
      case GlowButtonVariant.dark:
        return Colors.white.withValues(alpha: 0.85);
      case GlowButtonVariant.outline:
        return color;
      case GlowButtonVariant.text:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(_foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _foreground,
                  ),
                ),
              ),
            ],
          );

    final button = Material(
      color: _background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isDisabled ? null : onPressed,
        child: Container(
          height: 48,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: switch (variant) {
              GlowButtonVariant.outline => Border.all(
                color: color.withValues(alpha: 0.6),
              ),
              GlowButtonVariant.dark => Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              GlowButtonVariant.filled || GlowButtonVariant.text => null,
            },
          ),
          child: content,
        ),
      ),
    );

    if (variant != GlowButtonVariant.filled || _isDisabled) return button;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AsonGlow.of(color, blur: 18, opacity: 0.5),
      ),
      child: button,
    );
  }
}
