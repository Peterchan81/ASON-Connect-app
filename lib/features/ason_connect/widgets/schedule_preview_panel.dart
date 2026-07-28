// 입력창 바로 위에 표시하는 컴팩트한 실시간 정리 패널입니다.
// 채팅 전체를 가리는 큰 확인 카드 대신, 이 패널 하나로 분석 중/정보 부족/
// 수정 가능/동기화 준비/동기화 완료/동기화 실패 상태를 모두 보여줍니다.
// 아무 내용도 없으면 아예 그리지 않아(SizedBox.shrink) 채팅을 가리지 않고,
// 내용이 생기면 작은 카드 하나만큼만 자리를 차지합니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/draft_command.dart';
import '../services/summary_builder.dart';

enum SchedulePanelState {
  analyzing, // 분석 중 (실시간 미리보기 계산 중)
  missingInfo, // 정보 부족
  editable, // 수정 가능(아직 동기화 전)
  readyToSync, // 동기화 준비 완료
  syncing, // 동기화 중
  synced, // 동기화 완료
  failed, // 동기화 실패
}

extension on SchedulePanelState {
  String get label {
    switch (this) {
      case SchedulePanelState.analyzing:
        return '분석 중';
      case SchedulePanelState.missingInfo:
        return '정보 부족';
      case SchedulePanelState.editable:
        return '수정 가능';
      case SchedulePanelState.readyToSync:
        return '동기화 준비';
      case SchedulePanelState.syncing:
        return '동기화 중';
      case SchedulePanelState.synced:
        return '동기화 완료';
      case SchedulePanelState.failed:
        return '동기화 실패';
    }
  }

  Color get color {
    switch (this) {
      case SchedulePanelState.synced:
        return AsonColors.success;
      case SchedulePanelState.failed:
        return AsonColors.error;
      case SchedulePanelState.analyzing:
        return AsonColors.blueNeon;
      default:
        return AsonColors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case SchedulePanelState.analyzing:
        return Icons.auto_awesome_rounded;
      case SchedulePanelState.missingInfo:
        return Icons.help_outline_rounded;
      case SchedulePanelState.editable:
        return Icons.edit_note_rounded;
      case SchedulePanelState.readyToSync:
        return Icons.cloud_upload_outlined;
      case SchedulePanelState.syncing:
        return Icons.sync_rounded;
      case SchedulePanelState.synced:
        return Icons.check_circle_rounded;
      case SchedulePanelState.failed:
        return Icons.error_outline_rounded;
    }
  }
}

class SchedulePreviewPanel extends StatelessWidget {
  const SchedulePreviewPanel({
    super.key,
    required this.draft,
    required this.isPreviewOnly,
    required this.syncError,
    this.onEdit,
    this.onSync,
  });

  /// 지금 보여줄 내용입니다. 아직 아무 것도 입력하지 않았으면 null입니다.
  final DraftCommand? draft;

  /// true면 아직 전송하지 않은, 입력 중인 문장의 미리보기입니다.
  /// (수정/동기화 버튼을 제공하지 않습니다 — 먼저 전송해야 합니다)
  final bool isPreviewOnly;

  final String? syncError;
  final VoidCallback? onEdit;
  final VoidCallback? onSync;

  SchedulePanelState _stateFor(DraftCommand draft) {
    if (syncError != null) return SchedulePanelState.failed;
    if (draft.status == DraftCommandStatus.syncing) {
      return SchedulePanelState.syncing;
    }
    if (draft.status == DraftCommandStatus.synced) {
      return SchedulePanelState.synced;
    }
    if (isPreviewOnly) return SchedulePanelState.analyzing;
    if (draft.status == DraftCommandStatus.collecting ||
        draft.status == DraftCommandStatus.clarifyingCategory) {
      return SchedulePanelState.missingInfo;
    }
    if (draft.status == DraftCommandStatus.ready) {
      return SchedulePanelState.readyToSync;
    }
    // 남은 경우는 status == editing(수정할 내용을 자연어로 되묻는 중)입니다.
    // 답변할 때까지는 수정/동기화 버튼을 다시 보여주지 않습니다.
    return SchedulePanelState.editable;
  }

  List<MapEntry<String, String>> _rows(DraftCommand draft) {
    if (draft.category == DraftCommandCategory.schedule ||
        draft.category == DraftCommandCategory.todo) {
      return [
        MapEntry('날짜', draft.date ?? '-'),
        MapEntry('시간', draft.time ?? '-'),
        MapEntry('내용', draft.title ?? '-'),
        MapEntry('장소', draft.location ?? '-'),
        MapEntry('알림', draft.alarm ?? '없음'),
        MapEntry('반복', draft.repeatOption ?? '없음'),
        MapEntry('메모', draft.memo ?? '-'),
      ];
    }
    if (draft.category == null) return const [];
    return const SummaryBuilder().rows(draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    if (draft == null) return const SizedBox.shrink();

    final state = _stateFor(draft);
    // "editable" 상태는 실제로는 status == editing(자연어 수정 답변을 기다리는
    // 중)이므로, 버튼을 다시 보여주지 않습니다. 기존 "수정" 대화 흐름과 동일합니다.
    final canEditOrSync =
        !isPreviewOnly &&
        (state == SchedulePanelState.readyToSync ||
            state == SchedulePanelState.failed);

    return GlowCard(
      key: const ValueKey('schedule-preview-panel'),
      glowColor: state.color,
      glowOpacity: 0.22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(state.icon, size: 16, color: state.color),
              const SizedBox(width: 6),
              Text(
                draft.category?.label ?? '분석 중',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: state.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          if (draft.category != null) ...[
            const SizedBox(height: 8),
            for (final row in _rows(draft))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        row.key,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: state.color.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (syncError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                syncError!,
                style: TextStyle(fontSize: 11.5, color: AsonColors.error),
              ),
            ),
          if (isPreviewOnly)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Enter를 누르거나 전송하면 확정됩니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          if (canEditOrSync) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                    label: '수정',
                    variant: GlowButtonVariant.dark,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlowButton(
                    label: 'ASON Core에 동기화',
                    isLoading: state == SchedulePanelState.syncing,
                    onPressed: onSync,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
