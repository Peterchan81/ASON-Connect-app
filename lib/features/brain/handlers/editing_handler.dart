// 수정 대화(status == editing)를 처리합니다: 어떤 항목을 어떤 값으로 바꾸려는지
// 해석하고, 적용한 뒤 다시 ready 상태(확인 카드)로 돌려보냅니다.

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/command_parser_service.dart';
import '../../ason_connect/services/korean_particles.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../services/brain_result_composer.dart';
import 'brain_turn_handler.dart';

class EditingHandler implements BrainTurnHandler {
  const EditingHandler();

  @override
  bool canHandle(BrainContext context) =>
      context.draft?.status == DraftCommandStatus.editing;

  @override
  BrainResult handle(BrainContext context) {
    final draft = context.draft!;
    final rawText = context.rawText;

    final fields = _correctionFieldsFor(draft);
    final correction = context.entityAnalyzer.parseCorrection(rawText, fields);

    if (correction == null) {
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: const [
          BrainMessage(
            '어떤 항목을 어떻게 바꿀지 다시 말씀해 주세요.',
            type: ChatMessageType.question,
          ),
        ],
        turnType: BrainTurnType.editing,
      );
    }

    final updated = context.parser.applyFieldCorrection(draft, correction);
    final label =
        CommandParserService.fieldKeyToLabel[correction.field] ?? '내용';
    // 실제로 저장된 값을 기준으로 안내합니다. (예: "없어" -> "없음"으로 정리된 경우 반영)
    final appliedValue =
        context.parser.scheduleFieldValue(updated, correction.field) ??
        correction.newValue;

    final ready = updated.copyWith(status: DraftCommandStatus.ready);
    final changeMessage =
        '$label${KoreanParticles.eulReul(label)} '
        '$appliedValue${KoreanParticles.euroRo(appliedValue)} 변경했습니다.';

    return BrainResultComposer.compose(
      context: context,
      draft: ready,
      messages: [
        BrainMessage(changeMessage),
        BrainMessage(
          ready.category!.savedMessage,
          type: ChatMessageType.summary,
        ),
      ],
      turnType: BrainTurnType.editing,
      changedFields: [correction.field],
    );
  }

  List<String> _correctionFieldsFor(DraftCommand draft) {
    switch (draft.category) {
      case DraftCommandCategory.schedule:
        return const [
          'date',
          'time',
          'location',
          'title',
          'alarm',
          'repeat',
          'memo',
        ];
      case DraftCommandCategory.health:
        return const ['date', 'healthItem', 'title'];
      case DraftCommandCategory.memo:
        return const ['title', 'memoType'];
      case DraftCommandCategory.project:
        return const ['title', 'projectAction', 'progress'];
      case DraftCommandCategory.todo:
        return const ['title'];
      case null:
        return const [];
    }
  }
}
