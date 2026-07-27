// 카테고리가 애매해서 되물었던 질문(status == clarifyingCategory)에 대한 사용자의
// 선택(확인) 응답을 처리합니다. 후보 중 하나를 골랐으면 CategoryDraftBuilder로
// draft를 시작하고, 무엇도 고르지 못했으면 일반 응답으로 정리합니다.

import '../../ason_connect/models/draft_command.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../services/brain_result_composer.dart';
import '../services/category_draft_builder.dart';
import 'brain_turn_handler.dart';

class ConfirmationHandler implements BrainTurnHandler {
  const ConfirmationHandler({this.draftBuilder = const CategoryDraftBuilder()});

  final CategoryDraftBuilder draftBuilder;

  @override
  bool canHandle(BrainContext context) =>
      context.draft?.status == DraftCommandStatus.clarifyingCategory;

  @override
  BrainResult handle(BrainContext context) {
    final draft = context.draft!;
    final rawText = context.rawText;

    DraftCommandCategory? chosen;
    final normalizedReply = rawText.replaceAll(' ', '');
    for (final candidate in draft.candidateCategories) {
      if (normalizedReply.contains(candidate.label.replaceAll(' ', ''))) {
        chosen = candidate;
        break;
      }
    }
    chosen ??= draft.candidateCategories.isNotEmpty
        ? draft.candidateCategories.first
        : null;

    if (chosen == null) {
      return BrainResultComposer.unclassified(context, rawText: rawText);
    }

    final analysisText = context.locationService.fixSpacingArtifacts(
      draft.originalText,
    );
    return draftBuilder.begin(context, chosen, analysisText, draft.originalText);
  }
}
