// 화면 아래쪽에 항상 고정되는 입력 영역입니다. 아직 아무것도 입력하지
// 않았으면 크고 명확한 두 개의 선택 버튼(음성으로 말하기/문자로 입력하기)을
// 보여주고, 입력이 시작되면 실시간 정리 패널(들)과 음성/키보드 공용 입력
// 박스로 바뀝니다. 한 문장에 여러 의도가 섞여 있으면 정리 패널이 여러 개
// (items) 나타나고, 모두 준비되면 "모두 ASON에 동기화" 버튼도 함께 보여줍니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/connect_item.dart';
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import 'input_mode_start_selector.dart';
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
    this.showStartSelector = false,
    this.onSelectVoice,
    this.onSelectKeyboard,
    this.panelDraft,
    this.panelIsPreviewOnly = false,
    this.panelPendingQuestion,
    this.panelSyncError,
    this.onPanelEdit,
    this.onPanelSync,
    this.standaloneGuidance,
    this.items = const [],
    this.allItemsReady = false,
    this.onItemEdit,
    this.onItemSync,
    this.onSyncAll,
  });

  final AsonInputMode mode;
  final VoidCallback onToggleMode;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoiceMicPhase micPhase;
  final VoidCallback onMicPressed;

  /// 아직 음성/문자 중 어느 방식으로도 입력을 시작하지 않았을 때, 입력 박스
  /// 대신 크고 명확한 선택 버튼 두 개를 보여줄지 여부입니다.
  final bool showStartSelector;
  final VoidCallback? onSelectVoice;
  final VoidCallback? onSelectKeyboard;

  /// 입력창 바로 위 실시간 정리 패널에 보여줄 내용입니다. (커밋된 draft 또는
  /// 아직 전송하지 않은 문장의 미리보기) 둘 다 없으면 패널을 그리지 않습니다.
  /// [items]가 있으면(여러 의도로 나뉜 경우) 이 값 대신 [items]를 보여줍니다.
  final DraftCommand? panelDraft;
  final bool panelIsPreviewOnly;
  final String? panelPendingQuestion;
  final String? panelSyncError;
  final VoidCallback? onPanelEdit;
  final VoidCallback? onPanelSync;

  /// 아직 분류(카테고리)가 없어 정리 패널을 보여줄 수 없을 때(예: 애매한
  /// 일반 대화) 대신 보여줄 짧은 안내 문구입니다.
  final String? standaloneGuidance;

  /// 한 번의 입력에서 여러 의도로 나뉜 경우, 항목별로 보여줄 목록입니다.
  final List<ConnectItem> items;

  /// 모든 항목이 준비되어 "모두 ASON에 동기화" 버튼을 보여줄 수 있는지 여부입니다.
  final bool allItemsReady;
  final void Function(int index)? onItemEdit;
  final void Function(int index)? onItemSync;
  final VoidCallback? onSyncAll;

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
              if (items.isNotEmpty) ...[
                for (var i = 0; i < items.length; i++) ...[
                  SchedulePreviewPanel(
                    key: ValueKey('item-panel-$i-${items[i].draft.createdAt.microsecondsSinceEpoch}'),
                    draft: items[i].draft,
                    isPreviewOnly: false,
                    pendingQuestion: items[i].pendingQuestion,
                    syncError: items[i].syncError,
                    onEdit: onItemEdit == null ? null : () => onItemEdit!(i),
                    onSync: onItemSync == null ? null : () => onItemSync!(i),
                  ),
                  const SizedBox(height: 8),
                ],
                if (allItemsReady) ...[
                  GlowButton(
                    label: '모두 ASON에 동기화',
                    onPressed: onSyncAll,
                  ),
                  const SizedBox(height: 10),
                ],
              ] else if (panelDraft != null) ...[
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
              if (showStartSelector)
                InputModeStartSelector(
                  onSelectVoice: onSelectVoice ?? () {},
                  onSelectKeyboard: onSelectKeyboard ?? () {},
                )
              else
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
