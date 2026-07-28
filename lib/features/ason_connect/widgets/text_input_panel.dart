// 키보드 입력 모드에서 보여주는 문장 입력창 + 전송 버튼입니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';

class TextInputPanel extends StatelessWidget {
  const TextInputPanel({
    super.key,
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  /// Enter 키로 전송하고, Shift+Enter는 줄바꿈으로 남겨두기 위한 처리입니다.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if (event is KeyDownEvent &&
        isEnter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      onSend();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                autofocus: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  hintText: '일정, 메모, 건강 내용을 말씀해 주세요.',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          GlowIconButton(icon: Icons.send_rounded, onPressed: onSend, size: 40),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}
