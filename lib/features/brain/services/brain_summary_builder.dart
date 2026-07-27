// 확인 카드를 보여줄 준비가 되었는지만 판단합니다. 실제 표시 내용(제목/행)은
// 화면이 기존 SummaryBuilder(ason_connect/services)로 계속 그립니다. BrainEngine은
// 이 클래스로 "이번 턴에 Summary가 준비됐는지" 여부만 BrainResult에 담습니다.

import '../../ason_connect/models/draft_command.dart';

class BrainSummaryBuilder {
  const BrainSummaryBuilder();

  bool isReady(DraftCommand? draft) {
    if (draft == null) return false;
    return draft.status == DraftCommandStatus.ready ||
        draft.status == DraftCommandStatus.editing;
  }
}
