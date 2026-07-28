// 화면 아래쪽에 항상 고정되는 입력 영역입니다.
// 실시간 정리 패널(있으면)과, 음성/키보드 공용 입력 박스 하나로 구성됩니다.
// 종류를 먼저 고르는 선택 화면은 없습니다 — 앱을 열면 곧바로 입력할 수 있습니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import 'schedule_preview_panel.dart';
import 'unified_input_box.dart';

export 'unified_input_box.dart' show AsonInputMode;

class InputArea extends StatelessWidget {
  const InputArea({
    super.key,
    required this.mode,
    required this.onToggleMode,
    required this.controller,
    required this.onSend,
    required this.micPhase,
    required this.onMicPressed,
    this.panelDraft,
    this.panelIsPreviewOnly = false,
    this.panelPendingQuestion,
    this.panelSyncError,
    this.onPanelEdit,
    this.onPanelSync,
    this.standaloneGuidance,
  });

  final AsonInputMode mode;
  final VoidCallback onToggleMode;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoiceMicPhase micPhase;
  final VoidCallback onMicPressed;

  /// 입력창 바로 위 실시간 정리 패널에 보여줄 내용입니다. (커밋된 draft 또는
  /// 아직 전송하지 않은 문장의 미리보기) 둘 다 없으면 패널을 그리지 않습니다.
  final DraftCommand? panelDraft;
  final bool panelIsPreviewOnly;
  final String? panelPendingQuestion;
  final String? panelSyncError;
  final VoidCallback? onPanelEdit;
  final VoidCallback? onPanelSync;

  /// 아직 분류(카테고리)가 없어 정리 패널을 보여줄 수 없을 때(예: 애매한
  /// 일반 대화) 대신 보여줄 짧은 안내 문구입니다.
  final String? standaloneGuidance;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? AsonColors.lightBackground.withValues(alpha: 0.96)
            : AsonColors.darkNavy.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (panelDraft != null) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SchedulePreviewPanel(
                    key: const ValueKey('panel'),
                    draft: panelDraft,
                    isPreviewOnly: panelIsPreviewOnly,
                    pendingQuestion: panelPendingQuestion,
                    syncError: panelSyncError,
                    onEdit: onPanelEdit,
                    onSync: onPanelSync,
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (standaloneGuidance != null) ...[
                GlowCard(
                  key: const ValueKey('standalone-guidance'),
                  glowColor: AsonColors.blueNeon,
                  glowOpacity: 0.2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    standaloneGuidance!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AsonColors.onBackground(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              UnifiedInputBox(
                mode: mode,
                onToggleMode: onToggleMode,
                controller: controller,
                onSend: onSend,
                micPhase: micPhase,
                onMicPressed: onMicPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
