// 입력창 바로 위에 표시하는 컴팩트한 실시간 정리 패널입니다.
// ASON Connect의 유일한 결과 화면입니다. 채팅 이력 없이, 이 패널 하나로
// 분석 중/정보 부족(되묻는 질문 포함)/수정 가능/동기화 준비/동기화 중/
// 동기화 완료/동기화 실패 상태를 모두 보여줍니다. 아무 내용도 없으면 아예
// 그리지 않고(SizedBox.shrink), 내용이 생기면 필요한 필드만 최소한으로
// 보여줍니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/draft_command.dart';

enum SchedulePanelState {
  analyzing, // 분석 중 (실시간 미리보기 계산 중)
  missingInfo, // 정보 부족 (되묻는 중)
  readyToSync, // 수정 가능 / 동기화 준비
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
    required this.pendingQuestion,
    required this.syncError,
    this.onEdit,
    this.onSync,
  });

  /// 지금 보여줄 내용입니다. 아직 아무 것도 입력하지 않았으면 null입니다.
  final DraftCommand? draft;

  /// true면 아직 전송하지 않은, 입력 중인 문장의 미리보기입니다.
  /// (수정/동기화 버튼을 제공하지 않습니다 — 먼저 전송해야 합니다)
  final bool isPreviewOnly;

  /// 정보가 부족해 ASON이 되묻는 중일 때 보여줄 질문입니다.
  final String? pendingQuestion;

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
    // ready 또는 editing(자연어 수정 답변을 기다리는 중) 모두 카드 자체는
    // 계속 보여주되, editing 동안에는 버튼만 잠시 숨깁니다.
    return SchedulePanelState.readyToSync;
  }

  /// 일정은 핵심 필드(날짜/시간/내용/장소/알림)만 항상 보여주고, 반복/메모는
  /// 값이 있을 때만 보여줍니다. 그 외 카테고리는 한 줄 요약만 보여줍니다.
  List<MapEntry<String, String>> _rows(DraftCommand draft) {
    if (draft.category == DraftCommandCategory.schedule ||
        draft.category == DraftCommandCategory.todo) {
      final rows = [
        MapEntry('날짜', draft.date ?? '-'),
        MapEntry('시간', draft.time ?? '-'),
        MapEntry('내용', draft.title ?? '-'),
        MapEntry('장소', draft.location ?? '-'),
        MapEntry('알림', draft.alarm ?? '없음'),
      ];
      final repeat = draft.repeatOption;
      if (repeat != null && repeat.trim().isNotEmpty && repeat != '없음') {
        rows.add(MapEntry('반복', repeat));
      }
      final memo = draft.memo;
      if (memo != null && memo.trim().isNotEmpty) {
        rows.add(MapEntry('메모', memo));
      }
      return rows;
    }
    if (draft.category == DraftCommandCategory.health) {
      return [MapEntry(draft.healthItem ?? '건강', draft.title ?? '-')];
    }
    if (draft.category == DraftCommandCategory.dailyGoal) {
      final rows = [MapEntry('내용', draft.title ?? '-')];
      final repeat = draft.repeatOption;
      if (repeat != null && repeat.trim().isNotEmpty && repeat != '없음') {
        rows.add(MapEntry('반복', repeat));
      }
      return rows;
    }
    // 메모/프로젝트/다이어리 등은 한 줄 내용만 보여줍니다.
    return [MapEntry('내용', draft.title ?? '-')];
  }

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    if (draft == null) return const SizedBox.shrink();

    final state = _stateFor(draft);
    final isEditing = draft.status == DraftCommandStatus.editing;
    final canEditOrSync =
        !isPreviewOnly &&
        !isEditing &&
        (state == SchedulePanelState.readyToSync ||
            state == SchedulePanelState.syncing ||
            state == SchedulePanelState.failed);
    final textColor = AsonColors.onBackground(context);
    final mutedColor = AsonColors.onBackgroundMuted(context);

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
                style: TextStyle(fontSize: 11.5, color: mutedColor),
              ),
            ],
          ),
          if (pendingQuestion != null) ...[
            const SizedBox(height: 8),
            Text(
              pendingQuestion!,
              style: TextStyle(fontSize: 13, color: textColor, height: 1.35),
            ),
          ] else if (draft.category != null) ...[
            const SizedBox(height: 8),
            for (final row in _rows(draft))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: TextStyle(fontSize: 12.5, color: textColor),
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
          if (canEditOrSync && draft.validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                draft.validationMessage!,
                style: TextStyle(fontSize: 11.5, color: AsonColors.error),
              ),
            ),
          if (isPreviewOnly)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Enter를 누르거나 전송하면 확정됩니다.',
                style: TextStyle(fontSize: 11, color: mutedColor),
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
                    onPressed: state == SchedulePanelState.syncing
                        ? null
                        : onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlowButton(
                    label: 'ASON에 동기화',
                    isLoading: state == SchedulePanelState.syncing,
                    onPressed: draft.hasRequiredContent ? onSync : null,
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
