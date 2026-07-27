// 새 주제 입력을 처리합니다: Intent 분석 -> (애매하면 되묻기) -> Entity 추출 ->
// DraftCommand 생성 -> 다음 질문 또는 Summary 결정.
// draft가 없거나(ready/synced 등) 특별한 진행 중 상태가 아닐 때 항상 이 Handler가
// 마지막 수단으로 처리합니다.

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/korean_particles.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../services/brain_result_composer.dart';
import '../services/category_draft_builder.dart';
import 'brain_turn_handler.dart';

class NewTopicHandler implements BrainTurnHandler {
  const NewTopicHandler({this.draftBuilder = const CategoryDraftBuilder()});

  final CategoryDraftBuilder draftBuilder;

  @override
  bool canHandle(BrainContext context) => true; // 다른 Handler가 없으면 항상 처리

  @override
  BrainResult handle(BrainContext context) {
    final rawText = context.rawText;
    final analysisText = context.locationService.fixSpacingArtifacts(rawText);
    final intent = context.intentAnalyzer.analyze(analysisText);

    if (intent.isUnclassified) {
      return BrainResultComposer.unclassified(
        context,
        rawText: rawText,
        intent: intent,
      );
    }

    if (intent.isAmbiguous) {
      final first = intent.category;
      final second = intent.alternativeCategory!;
      final draft = DraftCommand(
        originalText: rawText,
        status: DraftCommandStatus.clarifyingCategory,
        candidateCategories: [first, second],
      );
      final message =
          '이 내용을 ${first.label}${KoreanParticles.euroRo(first.label)} 정리할까요, '
          '${second.label}${KoreanParticles.euroRo(second.label)} 정리할까요?';
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: [BrainMessage(message, type: ChatMessageType.question)],
        turnType: BrainTurnType.newTopic,
        intent: intent,
        isUncertain: true,
      );
    }

    return draftBuilder.begin(
      context,
      intent.category,
      analysisText,
      rawText,
      intent: intent,
    );
  }
}
