// 대화 단계별 처리기(Handler)의 공통 인터페이스입니다.
// BrainEngine은 canHandle이 true인 첫 Handler를 찾아 handle을 호출하기만 합니다.
// 실제 판단(분류/추출/질문 생성 등)은 각 Handler 내부에 있습니다.
//
// Widget이나 BuildContext에 의존하지 않으며, 지금은 모든 판단이 동기(규칙 기반)라
// Future를 쓰지 않습니다. 향후 비동기 AI 호출이 필요해지면 이 인터페이스의 handle()을
// Future<BrainResult>로 바꾸면 됩니다.

import '../context/brain_context.dart';
import '../models/brain_result.dart';

abstract class BrainTurnHandler {
  /// 지금 context(입력/현재 draft 상태)를 이 Handler가 처리할 수 있는지 여부입니다.
  bool canHandle(BrainContext context);

  /// 실제 처리를 수행하고 BrainResult를 돌려줍니다. canHandle이 true일 때만 호출됩니다.
  BrainResult handle(BrainContext context);
}
