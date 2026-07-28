// 카테고리가 확정된 순간(새 분류든, 애매함을 해소한 뒤든) 실제 DraftCommand를
// 만들기 시작하는 로직입니다. NewTopicHandler(새 분류)와 ConfirmationHandler(애매함
// 해소)가 똑같이 필요로 하는 절차라서, 두 Handler가 함께 재사용하도록 이 곳에 모았습니다.
//
// 일정 외의 카테고리도 실제 사람과 대화하듯, 꼭 필요한 내용이 빠졌으면 곧바로
// 저장하지 않고 한 가지씩 되물은 뒤(status=collecting) 저장합니다.

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

  // 항목은 알아냈지만 값(수치/이름)이 빠진 건강 기록을 이어서 물어볼 때 쓰는 문구입니다.
  static const Map<String, String> _healthFollowUpQuestions = {
    '체중': '몸무게를 알려주세요. (예: 68kg)',
    '혈압': '혈압 수치를 알려주세요. (예: 128/82)',
    '혈당': '혈당 수치를 알려주세요.',
    '운동': '얼마나 운동하셨나요? (예: 30분)',
    '복용': '어떤 약을 드셨나요?',
  };

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
        messages: [
          BrainMessage(
            DraftCommandCategory.schedule.savedMessage,
            type: ChatMessageType.summary,
          ),
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
    final hasTitle = (entities.title ?? '').trim().isNotEmpty;

    final draft = DraftCommand(
      originalText: rawText,
      status: hasTitle
          ? DraftCommandStatus.ready
          : DraftCommandStatus.collecting,
      category: category,
      title: entities.title,
      memoType: entities.memoType,
    );

    if (!hasTitle) {
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: const [
          BrainMessage('제목을 입력해주세요.', type: ChatMessageType.question),
        ],
        turnType: BrainTurnType.newTopic,
        changedFields: _changedFields(entities),
        intent: intent,
        entities: entities,
      );
    }

    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: [
        BrainMessage(category.savedMessage, type: ChatMessageType.summary),
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
      messages: [
        BrainMessage(
          DraftCommandCategory.project.savedMessage,
          type: ChatMessageType.summary,
        ),
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
    final hasValue = (entities.title ?? '').trim().isNotEmpty;

    final draft = DraftCommand(
      originalText: rawText,
      status: hasValue
          ? DraftCommandStatus.ready
          : DraftCommandStatus.collecting,
      category: DraftCommandCategory.health,
      date: entities.date,
      healthItem: entities.healthItem,
      title: entities.title,
    );

    if (!hasValue) {
      final question =
          _healthFollowUpQuestions[entities.healthItem] ?? '내용을 알려주세요.';
      return BrainResultComposer.compose(
        context: context,
        draft: draft,
        messages: [BrainMessage(question, type: ChatMessageType.question)],
        turnType: BrainTurnType.newTopic,
        changedFields: _changedFields(entities),
        intent: intent,
        entities: entities,
      );
    }

    return BrainResultComposer.compose(
      context: context,
      draft: draft,
      messages: [
        BrainMessage(
          DraftCommandCategory.health.savedMessage,
          type: ChatMessageType.summary,
        ),
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
