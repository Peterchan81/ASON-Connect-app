// 일정을 제외한 카테고리(메모/건강 등)에서, 필요한 내용이 하나 빠져 있어
// 되물은 뒤(status == collecting) 돌아온 답변을 처리합니다. 일정과 달리
// 남는 항목이 항상 하나뿐이라 배치 질문 없이 그 자리에서 곧바로 채웁니다.

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../services/brain_result_composer.dart';
import 'brain_turn_handler.dart';

class SimpleContinuationHandler implements BrainTurnHandler {
  const SimpleContinuationHandler();

  @override
  bool canHandle(BrainContext context) {
    final draft = context.draft;
    return draft != null &&
        draft.status == DraftCommandStatus.collecting &&
        draft.category != DraftCommandCategory.schedule;
  }

  @override
  BrainResult handle(BrainContext context) {
    final draft = context.draft!;
    final answer = context.rawText.trim();

    final updated = draft.copyWith(
      title: answer,
      status: DraftCommandStatus.ready,
    );

    return BrainResultComposer.compose(
      context: context,
      draft: updated,
      messages: [
        BrainMessage(
          updated.category!.savedMessage,
          type: ChatMessageType.summary,
        ),
      ],
      turnType: BrainTurnType.simpleContinuation,
      changedFields: const ['title'],
    );
  }
}
