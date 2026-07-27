// ASON 통합 시스템으로 정리된 내용을 보내는 역할을 담당하는 서비스입니다.
// 지금 단계에서는 실제 ASON-Core 서버에 연결하지 않고, 가상으로 동기화를 흉내 냅니다.
// 나중에 실제 API로 교체할 때는 이 파일의 sync() 내부 구현만 바꾸면 됩니다.

import '../models/sync_payload.dart';

/// 동기화 처리 결과입니다.
class SyncResult {
  const SyncResult.success(this.payload)
    : isSuccess = true,
      errorMessage = null;

  const SyncResult.failure(String message)
    : isSuccess = false,
      payload = null,
      errorMessage = message;

  final bool isSuccess;
  final SyncPayload? payload;
  final String? errorMessage;
}

class MockSyncService {
  bool _isSyncing = false;

  /// 지금 동기화가 진행 중인지 여부입니다.
  bool get isSyncing => _isSyncing;

  /// 정리된 내용을 ASON 통합 시스템에 동기화합니다. (지금은 가상 처리)
  /// 이미 동기화가 진행 중이면 중복 요청을 막고 실패로 처리합니다.
  Future<SyncResult> sync(SyncPayload payload) async {
    if (_isSyncing) {
      return const SyncResult.failure('이미 동기화가 진행 중입니다.');
    }

    _isSyncing = true;
    try {
      // TODO: 실제 ASON-Core API 연동은 다음 개발 단계에서 이 부분을 교체합니다.
      await Future.delayed(const Duration(milliseconds: 1000));
      return SyncResult.success(payload);
    } catch (_) {
      return const SyncResult.failure('동기화 중 오류가 발생했습니다.');
    } finally {
      _isSyncing = false;
    }
  }
}
