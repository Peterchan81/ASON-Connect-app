// 모든 Handler가 BrainResult를 만들 때 거치는 단일 창구입니다.
// missingFields/summaryReady/syncReady/activeIntent/accumulatedEntities 계산을
// 한 곳에 모아서, Handler가 늘어나도 이 계산 로직이 여러 파일에 흩어지지 않게 합니다.

import '../../ason_connect/models/draft_command.dart';
import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../models/entity_result.dart';
import '../models/intent_result.dart';

class BrainResultComposer {
  const BrainResultComposer._();

  /// 공통 BrainResult 생성 창구입니다. 모든 Handler는 이 메서드로만 결과를 만듭니다.
  static BrainResult compose({
    required BrainContext context,
    required DraftCommand? draft,
    required List<BrainMessage> messages,
    required BrainTurnType turnType,
    List<String> changedFields = const [],
    IntentResult? intent,
    EntityResult? entities,
    bool isUncertain = false,
  }) {
    return BrainResult(
      draft: draft,
      messages: messages,
      intent: intent,
      entities: entities,
      summaryReady: context.summaryBuilder.isReady(draft),
      syncReady: context.syncBuilder.isReady(draft),
      isUncertain: isUncertain,
      // draft.category를 그대로 노출합니다. 이번 턴에 새로 분석하지 않았어도(수정/후속
      // 답변 턴) "지금 대화가 어떤 카테고리로 진행 중인지"는 거짓 없이 알 수 있습니다.
      activeIntent: draft?.category,
      accumulatedEntities: _accumulatedEntitiesFor(draft),
      changedFields: changedFields,
      turnType: turnType,
    );
  }

  /// 어떤 카테고리에도 해당하지 않는(또는 애매함이 끝내 풀리지 않은) 입력에 대한
  /// 공통 응답입니다. NewTopicHandler와 ConfirmationHandler가 함께 사용합니다.
  static BrainResult unclassified(
    BrainContext context, {
    required String rawText,
    IntentResult? intent,
  }) {
    return compose(
      context: context,
      draft: null,
      messages: [BrainMessage(context.heuristics.buildGeneralReply(rawText))],
      turnType: BrainTurnType.fallback,
      intent: intent,
      isUncertain: true,
    );
  }

  static EntityResult? _accumulatedEntitiesFor(DraftCommand? draft) {
    if (draft == null) return null;
    return EntityResult(
      date: draft.date,
      time: draft.time,
      location: draft.location,
      title: draft.title,
      healthItem: draft.healthItem,
      pendingLocationGuess: draft.pendingLocationGuess,
      pendingLocationOriginal: draft.pendingLocationOriginal,
    );
  }
}
