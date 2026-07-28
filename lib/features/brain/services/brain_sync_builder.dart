// ASON Core로 동기화할 준비가 되었는지만 판단합니다. 실제 SyncPayload 구성은
// 기존 SummaryBuilder(ason_connect/services)가 계속 담당합니다.

import '../../ason_connect/models/draft_command.dart';

class BrainSyncBuilder {
  const BrainSyncBuilder();

  bool isReady(DraftCommand? draft) =>
      draft != null && draft.status == DraftCommandStatus.ready;
}
