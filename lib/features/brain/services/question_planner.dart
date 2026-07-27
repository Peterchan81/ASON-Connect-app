// 부족한 필드를 바탕으로 "이번 턴에 실제로 무엇을 물어볼지" 계획하는 인터페이스입니다.

import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/command_parser_service.dart';
import '../../ason_connect/services/schedule_question_flow.dart';
import '../models/question_plan.dart';

abstract class QuestionPlanner {
  /// 이번 턴에 물어볼 질문을 계획합니다. 더 물어볼 것이 없으면 null입니다.
  QuestionPlan? plan(DraftCommand draft);
}

/// 기존 ScheduleQuestionFlow(배치 질문)와 CommandParserService(장소 재확인 질문)를
/// 그대로 재사용하는 구현입니다.
class RuleBasedQuestionPlanner implements QuestionPlanner {
  RuleBasedQuestionPlanner({
    required this._parser,
    required this._questionFlow,
  });

  final CommandParserService _parser;
  final ScheduleQuestionFlow _questionFlow;

  @override
  QuestionPlan? plan(DraftCommand draft) {
    // 장소가 불확실할 때만 예외적으로, 다른 질문보다 먼저 단독으로 확인합니다.
    if (draft.pendingLocationGuess != null &&
        (draft.location ?? '').trim().isEmpty) {
      return QuestionPlan(
        fields: const ['location'],
        questionText: _parser.questionForScheduleField('location', draft),
      );
    }

    final batch = _questionFlow.nextBatch(draft);
    if (batch.isEmpty) return null;

    return QuestionPlan(
      fields: batch,
      questionText: _questionFlow.questionFor(batch, draft),
    );
  }
}
