// 일정 정보를 수집하는 중(status == collecting, category == schedule)에 오는
// 후속 답변을 처리합니다. 장소가 불확실할 때의 "~가 맞나요?" 확인/취소 응답도
// 이 Handler 안에서 함께 다룹니다(일정 수집 흐름의 일부이기 때문입니다).

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../services/brain_result_composer.dart';
import 'brain_turn_handler.dart';

class ScheduleContinuationHandler implements BrainTurnHandler {
  const ScheduleContinuationHandler();

  @override
  bool canHandle(BrainContext context) {
    final draft = context.draft;
    return draft != null &&
        draft.status == DraftCommandStatus.collecting &&
        draft.category == DraftCommandCategory.schedule;
  }

  @override
  BrainResult handle(BrainContext context) {
    final draft = context.draft!;
    final rawAnswer = context.rawText;

    // 장소 확인 질문("~가 맞나요?")에 대한 단독 답변인 경우입니다.
    if (draft.pendingLocationGuess != null &&
        (draft.location ?? '').trim().isEmpty) {
      return _resolveLocationConfirmation(context, draft, rawAnswer);
    }

    final batch =
        context.questionPlanner.plan(draft)?.fields ?? const <String>[];
    if (batch.isEmpty) {
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: const [],
        turnType: BrainTurnType.scheduleContinuation,
      );
    }

    // 사용자가 줄바꿈이나 쉼표로 구분해서 여러 답을 한 번에 줄 수 있습니다.
    final segments = rawAnswer
        .split(RegExp(r'[\n,]'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    var updated = draft;
    final changed = <String>[];
    final answerCount = segments.length < batch.length
        ? segments.length
        : batch.length;
    for (var i = 0; i < answerCount; i++) {
      final field = batch[i];
      // 알림 질문에 "아니요"처럼 거절 의사를 밝히면 "없음"으로 정리합니다.
      final value =
          field == 'alarm' && context.heuristics.isNegative(segments[i])
          ? '없음'
          : segments[i];
      updated = context.parser.assignScheduleField(updated, field, value);
      changed.add(field);
    }

    return _finishTurn(context, updated, changedFields: changed);
  }

  BrainResult _resolveLocationConfirmation(
    BrainContext context,
    DraftCommand draft,
    String rawAnswer,
  ) {
    DraftCommand updated;
    var changed = const <String>['location'];

    if (context.heuristics.isAffirmative(rawAnswer)) {
      updated = context.parser.assignScheduleField(
        draft,
        'location',
        draft.pendingLocationGuess!,
      );
    } else if (context.heuristics.isNegative(rawAnswer)) {
      final cleared = draft.copyWith(clearPendingLocation: true);
      return BrainResultComposer.compose(
        context: context,
        draft: cleared,
        messages: const [
          BrainMessage('장소를 다시 알려주세요.', type: ChatMessageType.question),
        ],
        turnType: BrainTurnType.scheduleContinuation,
      );
    } else {
      // 그 외 응답은 사용자가 직접 말해준 새 지명으로 보고 그대로 사용합니다.
      updated = context.parser.assignScheduleField(
        draft,
        'location',
        rawAnswer,
      );
    }

    return _finishTurn(context, updated, changedFields: changed);
  }

  /// 일정 필드를 채운 뒤 공통으로 실행합니다: 다 채워졌으면 확인 카드로, 아니면 다음 질문으로.
  BrainResult _finishTurn(
    BrainContext context,
    DraftCommand updated, {
    required List<String> changedFields,
  }) {
    if (context.missingFieldAnalyzer.missingFields(updated).isEmpty) {
      final ready = updated.copyWith(status: DraftCommandStatus.ready);
      return BrainResultComposer.compose(
        context: context,
        draft: ready,
        messages: const [
          BrainMessage('ASON에 다음 내용만 동기화합니다.', type: ChatMessageType.summary),
        ],
        turnType: BrainTurnType.scheduleContinuation,
        changedFields: changedFields,
      );
    }

    final plan = context.questionPlanner.plan(updated);
    return BrainResultComposer.compose(
      context: context,
      draft: updated,
      messages: plan == null
          ? const []
          : [BrainMessage(plan.questionText, type: ChatMessageType.question)],
      turnType: BrainTurnType.scheduleContinuation,
      changedFields: changedFields,
    );
  }
}
