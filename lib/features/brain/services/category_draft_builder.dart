// 카테고리가 확정된 순간(새 분류든, 애매함을 해소한 뒤든) 실제 DraftCommand를
// 만들기 시작하는 로직입니다. NewTopicHandler(새 분류)와 ConfirmationHandler(애매함
// 해소)가 똑같이 필요로 하는 절차라서, 두 Handler가 함께 재사용하도록 이 곳에 모았습니다.

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../models/entity_result.dart';
import '../models/intent_result.dart';
import 'brain_result_composer.dart';

class CategoryDraftBuilder {
  const CategoryDraftBuilder();

  static const String _readyReplyText = 'ASON에 다음 내용만 동기화합니다.';

  BrainResult begin(
    BrainContext context,
    DraftCommandCategory category,
    String analysisText,
    String rawText, {
    IntentResult? intent,
  }) {
    switch (category) {
      case DraftCommandCategory.schedule:
        return _beginSchedule(context, analysisText, rawText, intent: intent);
      case DraftCommandCategory.memo:
      case DraftCommandCategory.todo:
        return _beginSimpleContent(
          context,
          category,
          analysisText,
          rawText,
          intent: intent,
        );
      case DraftCommandCategory.project:
        return _beginProject(context, analysisText, rawText, intent: intent);
      case DraftCommandCategory.health:
        return _beginHealth(context, analysisText, rawText, intent: intent);
    }
  }

  BrainResult _beginSchedule(
    BrainContext context,
    String analysisText,
    String rawText, {
    IntentResult? intent,
  }) {
    final entities = context.entityAnalyzer.extract(
      DraftCommandCategory.schedule,
      analysisText,
    );
    var draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.collecting,
      category: DraftCommandCategory.schedule,
      date: entities.date,
      time: entities.time,
      location: entities.location,
      title: entities.title,
      pendingLocationGuess: entities.pendingLocationGuess,
      pendingLocationOriginal: entities.pendingLocationOriginal,
    );

    if (context.missingFieldAnalyzer.missingFields(draft).isEmpty) {
      draft = draft.copyWith(status: DraftCommandStatus.ready);
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: const [
          BrainMessage(_readyReplyText, type: ChatMessageType.summary),
        ],
        turnType: BrainTurnType.newTopic,
        changedFields: _changedFields(entities),
        intent: intent,
        entities: entities,
      );
    }

    final plan = context.questionPlanner.plan(draft);
    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: plan == null
          ? const []
          : [BrainMessage(plan.questionText, type: ChatMessageType.question)],
      turnType: BrainTurnType.newTopic,
      changedFields: _changedFields(entities),
      intent: intent,
      entities: entities,
    );
  }

  BrainResult _beginSimpleContent(
    BrainContext context,
    DraftCommandCategory category,
    String analysisText,
    String rawText, {
    IntentResult? intent,
  }) {
    final entities = context.entityAnalyzer.extract(category, analysisText);
    final draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.ready,
      category: category,
      title: entities.title,
      memoType: entities.memoType,
    );
    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: const [
        BrainMessage(_readyReplyText, type: ChatMessageType.summary),
      ],
      turnType: BrainTurnType.newTopic,
      changedFields: _changedFields(entities),
      intent: intent,
      entities: entities,
    );
  }

  BrainResult _beginProject(
    BrainContext context,
    String analysisText,
    String rawText, {
    IntentResult? intent,
  }) {
    final entities = context.entityAnalyzer.extract(
      DraftCommandCategory.project,
      analysisText,
    );
    final draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.project,
      title: entities.title,
      projectAction: entities.projectAction,
      progress: entities.progress,
    );
    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: const [
        BrainMessage(_readyReplyText, type: ChatMessageType.summary),
      ],
      turnType: BrainTurnType.newTopic,
      changedFields: _changedFields(entities),
      intent: intent,
      entities: entities,
    );
  }

  BrainResult _beginHealth(
    BrainContext context,
    String analysisText,
    String rawText, {
    IntentResult? intent,
  }) {
    final entities = context.entityAnalyzer.extract(
      DraftCommandCategory.health,
      analysisText,
    );
    final draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.health,
      date: entities.date,
      healthItem: entities.healthItem,
      title: entities.title,
    );
    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: const [
        BrainMessage(_readyReplyText, type: ChatMessageType.summary),
      ],
      turnType: BrainTurnType.newTopic,
      changedFields: _changedFields(entities),
      intent: intent,
      entities: entities,
    );
  }

  /// [entities]에서 실제로 값이 채워진 필드 key입니다. (거짓으로 만들어 내지 않고,
  /// 실제로 추출된 값만 반영합니다)
  List<String> _changedFields(EntityResult entities) {
    final changed = <String>[];
    if (entities.date != null) changed.add('date');
    if (entities.time != null) changed.add('time');
    if (entities.location != null) changed.add('location');
    if (entities.title != null) changed.add('title');
    if (entities.healthItem != null) changed.add('healthItem');
    if (entities.memoType != null) changed.add('memoType');
    if (entities.projectAction != null) changed.add('projectAction');
    if (entities.progress != null) changed.add('progress');
    return changed;
  }
}
