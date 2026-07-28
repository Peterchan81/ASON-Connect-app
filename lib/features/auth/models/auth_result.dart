// 로그인/회원가입 처리 결과입니다. 성공 여부와, 실패했을 때 화면에 그대로
// 보여줄 수 있는 한글 오류 메시지를 함께 담습니다.

class AuthResult {
  const AuthResult.success() : isSuccess = true, errorMessage = null;
  const AuthResult.failure(String message)
    : isSuccess = false,
      errorMessage = message;

  final bool isSuccess;
  final String? errorMessage;
}

/// 앱 시작 시 자동 로그인 시도 결과입니다.
enum AutoLoginStatus {
  /// 저장된 자동 로그인 정보가 없습니다. (최초 실행/자동 로그인 미선택)
  none,

  /// 저장된 정보로 자동 로그인에 성공했습니다.
  success,

  /// 저장된 정보가 있었지만 손상되었거나 더 이상 유효하지 않습니다.
  expired,
}

class AutoLoginResult {
  const AutoLoginResult._(this.status);
  const AutoLoginResult.none() : this._(AutoLoginStatus.none);
  const AutoLoginResult.success() : this._(AutoLoginStatus.success);
  const AutoLoginResult.expired() : this._(AutoLoginStatus.expired);

  final AutoLoginStatus status;

  bool get isSuccess => status == AutoLoginStatus.success;
  bool get isExpired => status == AutoLoginStatus.expired;
}
