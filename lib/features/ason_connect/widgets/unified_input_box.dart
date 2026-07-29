// ASON Connect의 유일한 입력 영역입니다. 음성/키보드 모드와 관계없이 항상
// 같은 위치·같은 크기의 박스 하나를 씁니다. 왼쪽에는 지금 모드를 다른
// 방식으로 바꿀 수 있는, 아이콘만 있지 않은 명확한 텍스트 버튼("문자로
// 입력하기"/"음성으로 입력하기")이 있습니다. 오른쪽 아이콘은 모드에 맞는
// 실행 동작입니다(키보드=전송, 음성=듣기 시작/중지).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../models/voice_mic_phase.dart';

enum AsonInputMode { voice, keyboard }

class UnifiedInputBox extends StatelessWidget {
  const UnifiedInputBox({
    super.key,
    required this.mode,
    required this.onToggleMode,
    required this.controller,
    required this.onSend,
    required this.micPhase,
    required this.onMicPressed,
  });

  final AsonInputMode mode;
  final VoidCallback onToggleMode;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoiceMicPhase micPhase;
  final VoidCallback onMicPressed;

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
    final isVoice = mode == AsonInputMode.voice;
    final micColor = switch (micPhase) {
      VoiceMicPhase.error => AsonColors.error,
      VoiceMicPhase.listening => AsonColors.blueNeon,
      _ => AsonColors.primary,
    };

    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onToggleMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isVoice ? '문자로 입력하기' : '음성으로 입력하기',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AsonColors.primary,
                ),
              ),
            ),
            Expanded(
              child: isVoice
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.text.isEmpty
                            ? micPhase.statusText
                            : controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: controller.text.isEmpty
                              ? AsonColors.onBackgroundMuted(context)
                              : AsonColors.onBackground(context),
                        ),
                      ),
                    )
                  : Focus(
                      onKeyEvent: _handleKeyEvent,
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AsonColors.onBackground(context),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          hintText: '말하거나 입력해 주세요.',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AsonColors.onBackgroundMuted(context),
                          ),
                        ),
                      ),
                    ),
            ),
            if (isVoice)
              GlowIconButton(
                icon: micPhase == VoiceMicPhase.listening
                    ? Icons.stop_rounded
                    : Icons.mic_rounded,
                color: micColor,
                size: 40,
                onPressed: micPhase == VoiceMicPhase.processing
                    ? null
                    : onMicPressed,
              )
            else
              GlowIconButton(
                icon: Icons.send_rounded,
                size: 40,
                onPressed: onSend,
              ),
          ],
        ),
      ),
    );
  }
}
