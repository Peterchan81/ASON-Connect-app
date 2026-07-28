// 화면 아래쪽에 항상 고정되는 입력 영역입니다.
// 아직 입력 방식을 고르지 않았다면 선택 UI(InputModeSelector)를 보여주고,
// 고른 뒤에는 선택된 방식만 크게 보여주고 작은 버튼으로 다른 방식으로 즉시 바꿀 수 있게 합니다.
// 동기화 중에는 방식과 상관없이 VoiceOrb의 Sync 표현을 보여줍니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import 'mode_switch_button.dart';
import 'schedule_preview_panel.dart';
import 'text_input_panel.dart';
import 'voice_input_card.dart';

class InputArea extends StatelessWidget {
  const InputArea({
    super.key,
    required this.inputMode,
    required this.onModeSelected,
    required this.controller,
    required this.onSend,
    required this.micPhase,
    required this.onMicPressed,
    required this.onToggleMode,
    this.isSyncing = false,
    this.panelDraft,
    this.panelIsPreviewOnly = false,
    this.panelSyncError,
    this.onPanelEdit,
    this.onPanelSync,
  });

  /// 아직 고르지 않았으면 null입니다.
  final AsonInputMode? inputMode;
  final ValueChanged<AsonInputMode> onModeSelected;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoiceMicPhase micPhase;
  final VoidCallback onMicPressed;
  final VoidCallback onToggleMode;
  final bool isSyncing;

  /// 입력창 바로 위 실시간 정리 패널에 보여줄 내용입니다. (커밋된 draft 또는
  /// 아직 전송하지 않은 문장의 미리보기) 둘 다 없으면 패널을 그리지 않습니다.
  final DraftCommand? panelDraft;
  final bool panelIsPreviewOnly;
  final String? panelSyncError;
  final VoidCallback? onPanelEdit;
  final VoidCallback? onPanelSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AsonColors.darkNavy.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 동기화 중에는 아래 큰 표시(_buildSyncing)가 이미 진행 상태를
              // 보여주므로, 패널과 중복되지 않도록 그때는 숨깁니다.
              if (!isSyncing && panelDraft != null) ...[
                SchedulePreviewPanel(
                  draft: panelDraft,
                  isPreviewOnly: panelIsPreviewOnly,
                  syncError: panelSyncError,
                  onEdit: onPanelEdit,
                  onSync: onPanelSync,
                ),
                const SizedBox(height: 10),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isSyncing) return _buildSyncing();
    if (inputMode == null) {
      return InputModeSelector(
        key: const ValueKey('selector'),
        onSelected: onModeSelected,
      );
    }
    return inputMode == AsonInputMode.voice
        ? _buildVoiceMode()
        : _buildKeyboardMode();
  }

  Widget _buildSyncing() {
    return Column(
      key: const ValueKey('syncing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const VoiceOrb(state: VoiceOrbState.syncing, size: 72),
        const SizedBox(height: 10),
        Text(
          'ASON Core에 동기화하는 중입니다...',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceMode() {
    return Column(
      key: const ValueKey('voice'),
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceInputCard(phase: micPhase, onMicPressed: onMicPressed),
        const SizedBox(height: 6),
        ModeSwitchButton(toVoice: false, onPressed: onToggleMode),
      ],
    );
  }

  Widget _buildKeyboardMode() {
    return Column(
      key: const ValueKey('keyboard'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TextInputPanel(controller: controller, onSend: onSend),
        const SizedBox(height: 8),
        ModeSwitchButton(toVoice: true, onPressed: onToggleMode),
      ],
    );
  }
}
