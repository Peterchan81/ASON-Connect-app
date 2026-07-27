// 빈 입력을 처리합니다. (미분류 입력은 분류를 시도해 본 뒤에야 알 수 있으므로,
// 그 판단은 NewTopicHandler/ConfirmationHandler가 BrainResultComposer.unclassified로
// 처리합니다. 이 Handler는 분류 시도 자체가 필요 없는 "완전히 빈 입력"만 다룹니다.)

import '../context/brain_context.dart';
import '../models/brain_result.dart';
import '../models/brain_turn_type.dart';
import '../services/brain_result_composer.dart';
import 'brain_turn_handler.dart';

class FallbackHandler implements BrainTurnHandler {
  const FallbackHandler();

  @override
  bool canHandle(BrainContext context) => context.rawText.isEmpty;

  @override
  BrainResult handle(BrainContext context) => BrainResultComposer.compose(
    context: context,
    draft: context.draft,
    messages: const [],
    turnType: BrainTurnType.fallback,
  );
}
