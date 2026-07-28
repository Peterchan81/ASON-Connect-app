// ASON Design System의 입력란입니다. (Design System 공통 컴포넌트)
// 어두운 반투명 배경 + 얇은 오렌지 네온 테두리, 포커스 시 Glow가 강해집니다.
// 로그인/회원가입 화면에서 공통으로 사용합니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';

class NeonTextField extends StatefulWidget {
  const NeonTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final String? label;
  final bool obscureText;

  /// true면 오른쪽에 비밀번호 표시/숨김 토글 아이콘을 보여줍니다.
  final bool showObscureToggle;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _obscure = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? AsonColors.error
        : AsonColors.primary.withValues(alpha: _isFocused ? 0.9 : 0.35);
    final textColor = AsonColors.onBackground(context);
    final mutedColor = AsonColors.onBackgroundMuted(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: isLight
                ? AsonColors.lightSurface
                : AsonColors.surfaceNavy.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: _isFocused
                ? AsonGlow.of(AsonColors.primary, blur: 14, opacity: 0.35)
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.showObscureToggle ? _obscure : widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            style: TextStyle(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(fontSize: 14, color: mutedColor),
              suffixIcon: widget.showObscureToggle
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: mutedColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: 12, color: AsonColors.error),
          ),
        ],
      ],
    );
  }
}
