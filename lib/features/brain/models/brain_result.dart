// BrainEngine.process()가 한 턴을 판단한 뒤 돌려주는 결과입니다.
// ConversationManager는 이 결과를 그대로 화면 상태(대화 메시지, DraftCommand)에
// 반영하기만 하면 되고, 그 안의 판단 로직은 알 필요가 없습니다.

import '../../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../../ason_connect/models/draft_command.dart';
import 'brain_turn_type.dart';
import 'entity_result.dart';
import 'intent_result.dart';

/// ASON이 이번 턴에 대화창에 남길 메시지 한 건입니다. (id/시각은 ConversationManager가
/// 실제 ChatMessage로 만들 때 채웁니다)
class BrainMessage {
  const BrainMessage(this.text, {this.type = ChatMessageType.normal});

  final String text;
  final ChatMessageType type;

  @override
  String toString() => 'BrainMessage($type: $text)';
}

class BrainResult {
  const BrainResult({
    required this.draft,
    this.messages = const [],
    this.intent,
    this.entities,
    this.missingFields = const [],
    this.summaryReady = false,
    this.syncReady = false,
    this.isUncertain = false,
    this.activeIntent,
    this.accumulatedEntities,
    this.changedFields = const [],
    this.turnType = BrainTurnType.fallback,
  });

  /// 이번 턴 처리 후 갱신된 DraftCommand입니다. 새 주제가 분류되지 않았으면 null입니다.
  final DraftCommand? draft;

  /// ASON이 이번 턴에 대화창에 남길 메시지들입니다. (보통 0~2개)
  final List<BrainMessage> messages;

  /// 이번 턴에 새로 분석한 Intent입니다. 분석이 없었던 턴(수정/후속 답변 등)에는 null입니다.
  /// "이번 턴에 실제로 분석이 있었는가"를 그대로 보여주며, 분석이 없었다고 값을
  /// 지어내지 않습니다. 지금 대화가 어떤 카테고리인지 항상 알고 싶다면 [activeIntent]를
  /// 사용하세요.
  final IntentResult? intent;

  /// 이번 턴에 새로 추출한 Entity입니다. [intent]와 마찬가지로 분석이 없었던 턴에는
  /// null입니다. 지금까지 누적된 값이 필요하면 [accumulatedEntities]를 사용하세요.
  final EntityResult? entities;

  /// 아직 채워지지 않은 필드입니다. (일정 수집 중이 아니면 항상 비어 있습니다)
  final List<String> missingFields;

  /// 확인 카드를 보여줄 준비가 되었는지 여부입니다.
  final bool summaryReady;

  /// ASON Core로 동기화할 준비가 되었는지 여부입니다.
  final bool syncReady;

  /// 이번 턴의 판단이 불확실했는지(미분류/애매 분류) 여부입니다.
  final bool isUncertain;

  /// 지금 대화가 어떤 카테고리로 진행 중인지입니다. draft.category를 그대로 노출하므로,
  /// 이번 턴에 새로 분류하지 않았어도(수정/후속 답변 턴) 항상 참인 값입니다.
  final DraftCommandCategory? activeIntent;

  /// 지금까지 draft에 실제로 쌓인 값들입니다. 이번 턴에 새로 추출하지 않은 필드도
  /// 포함되며, draft에 실제로 저장된 값만 담기므로 거짓으로 만들어 낸 값은 없습니다.
  final EntityResult? accumulatedEntities;

  /// 이번 턴에 실제로 값이 바뀐 필드 key입니다. (변경이 없었으면 빈 리스트)
  final List<String> changedFields;

  /// 이번 턴을 어떤 Handler가 처리했는지입니다.
  final BrainTurnType turnType;

  @override
  String toString() =>
      'BrainResult(turnType: $turnType, messages: $messages, '
      'missingFields: $missingFields, changedFields: $changedFields, '
      'summaryReady: $summaryReady, syncReady: $syncReady, isUncertain: $isUncertain)';
}
