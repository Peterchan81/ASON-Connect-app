// ASON Voice의 핵심 두뇌입니다.
//
// BrainEngine 자체는 오케스트레이션만 담당합니다: 의존성을 보관하고, 매 턴마다
// BrainContext를 만들고, 지금 상태에 맞는 Handler를 선택해서 실행하고, 그 결과를
// 돌려줍니다. 세부 Intent 분기, 일정 후속 답변 처리, 수정 문장 해석, 새 주제 분류,
// 질문 문구 생성, 필드별 세부 파싱은 모두 features/brain/handlers의 각 Handler와
// features/brain/services의 협력 클래스가 담당합니다.
//
// Flutter Widget이나 BuildContext에 의존하지 않는 순수 Dart 계층입니다.
// 이번 Sprint는 규칙 기반 Analyzer만 연결하며, 실제 AI(OpenAI/Gemini) 호출이나
// 서버 통신, 장기 기억, 사용자 데이터 저장은 하지 않습니다.

import '../ason_connect/models/chat_message.dart' show ChatMessageType;
import '../ason_connect/services/command_parser_service.dart';
import '../ason_connect/services/conversation_heuristics.dart';
import '../ason_connect/services/korean_location_service.dart';
import '../ason_connect/services/schedule_question_flow.dart';
import 'adapters/rule_based_entity_analyzer.dart';
import 'adapters/rule_based_intent_analyzer.dart';
import 'context/brain_context.dart';
import 'handlers/brain_turn_handler.dart';
import 'handlers/confirmation_handler.dart';
import 'handlers/editing_handler.dart';
import 'handlers/fallback_handler.dart';
import 'handlers/new_topic_handler.dart';
import 'handlers/schedule_continuation_handler.dart';
import 'handlers/simple_continuation_handler.dart';
import 'models/brain_input.dart';
import 'models/brain_result.dart';
import 'models/brain_turn_type.dart';
import 'services/brain_result_composer.dart';
import 'services/brain_summary_builder.dart';
import 'services/brain_sync_builder.dart';
import 'services/entity_analyzer.dart';
import 'services/intent_analyzer.dart';
import 'services/missing_field_analyzer.dart';
import 'services/question_planner.dart';

class BrainEngine {
  factory BrainEngine({
    CommandParserService? parser,
    KoreanLocationService? locationService,
    IntentAnalyzer? intentAnalyzer,
    EntityAnalyzer? entityAnalyzer,
    MissingFieldAnalyzer? missingFieldAnalyzer,
    QuestionPlanner? questionPlanner,
    ConversationHeuristics? heuristics,
    List<BrainTurnHandler>? handlers,
  }) {
    final resolvedLocationService = locationService ?? KoreanLocationService();
    final resolvedParser =
        parser ??
        CommandParserService(locationService: resolvedLocationService);
    final resolvedQuestionFlow = ScheduleQuestionFlow(parser: resolvedParser);

    return BrainEngine._(
      intentAnalyzer: intentAnalyzer ?? RuleBasedIntentAnalyzer(resolvedParser),
      entityAnalyzer: entityAnalyzer ?? RuleBasedEntityAnalyzer(resolvedParser),
      missingFieldAnalyzer:
          missingFieldAnalyzer ?? RuleBasedMissingFieldAnalyzer(resolvedParser),
      questionPlanner:
          questionPlanner ??
          RuleBasedQuestionPlanner(
            parser: resolvedParser,
            questionFlow: resolvedQuestionFlow,
          ),
      heuristics: heuristics ?? ConversationHeuristics(),
      parser: resolvedParser,
      locationService: resolvedLocationService,
      // 대화 단계에 맞는 Handler를 순서대로 검사합니다. NewTopicHandler는 항상
      // canHandle=true라서 목록 맨 끝에 두어 "다른 어떤 단계도 아니면 새 주제로
      // 시작한다"는 기존 동작을 그대로 재현합니다.
      handlers:
          handlers ??
          const [
            FallbackHandler(),
            ConfirmationHandler(),
            EditingHandler(),
            ScheduleContinuationHandler(),
            SimpleContinuationHandler(),
            NewTopicHandler(),
          ],
    );
  }

  BrainEngine._({
    required this._intentAnalyzer,
    required this._entityAnalyzer,
    required this._missingFieldAnalyzer,
    required this._questionPlanner,
    required this._heuristics,
    required this._parser,
    required this._locationService,
    required this._handlers,
  });

  final IntentAnalyzer _intentAnalyzer;
  final EntityAnalyzer _entityAnalyzer;
  final MissingFieldAnalyzer _missingFieldAnalyzer;
  final QuestionPlanner _questionPlanner;
  final ConversationHeuristics _heuristics;
  final CommandParserService _parser;
  final KoreanLocationService _locationService;
  final List<BrainTurnHandler> _handlers;
  final BrainSummaryBuilder _summaryBuilder = const BrainSummaryBuilder();
  final BrainSyncBuilder _syncBuilder = const BrainSyncBuilder();

  /// 사용자 입력 한 건을 판단합니다. 화면(위젯)이나 대화 이력은 몰라도 되고,
  /// 지금 draft 하나만 있으면 다음 상태를 결정할 수 있습니다.
  BrainResult process(BrainInput input) {
    final context = BrainContext(
      input: input,
      intentAnalyzer: _intentAnalyzer,
      entityAnalyzer: _entityAnalyzer,
      missingFieldAnalyzer: _missingFieldAnalyzer,
      questionPlanner: _questionPlanner,
      summaryBuilder: _summaryBuilder,
      syncBuilder: _syncBuilder,
      heuristics: _heuristics,
      parser: _parser,
      locationService: _locationService,
    );

    for (final handler in _handlers) {
      if (!handler.canHandle(context)) continue;

      try {
        return handler.handle(context);
      } catch (_) {
        // 공통 오류 처리: 어떤 Handler든 예상치 못하게 실패하면 앱이 죽는 대신
        // 안내 메시지와 함께 지금 draft를 그대로 유지합니다.
        return BrainResultComposer.compose(
          context: context,
          draft: context.draft,
          messages: const [
            BrainMessage(
              '요청을 처리하지 못했습니다. 다시 말씀해 주세요.',
              type: ChatMessageType.error,
            ),
          ],
          turnType: BrainTurnType.fallback,
        );
      }
    }

    // NewTopicHandler가 항상 canHandle=true라 이론상 도달하지 않는 안전망입니다.
    return BrainResultComposer.compose(
      context: context,
      draft: context.draft,
      messages: const [],
      turnType: BrainTurnType.fallback,
    );
  }
}
