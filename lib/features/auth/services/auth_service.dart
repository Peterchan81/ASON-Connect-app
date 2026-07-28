// ASON Connect의 로컬 로그인 서비스입니다.
// 이 앱은 별도의 서버가 없으므로(Brain Engine/데이터 저장 모두 기기 안에서만
// 동작), 계정도 SharedPreferences에 저장된 계정 목록을 기준으로 이 기기
// 안에서만 검증합니다. 비밀번호는 원문이 아니라 SHA-256 해시로만 저장합니다.
//
// 저장하는 값(자동 로그인 관련):
//   isLoggedIn / autoLoginEnabled / userId / nickname / session identifier
// 저장하지 않는 값: 비밀번호 원문, OAuth 토큰 원문 등 민감한 값.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ason_account.dart';
import '../models/auth_result.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _kAccounts = 'ason_accounts';
  static const String _kIsLoggedIn = 'ason_is_logged_in';
  static const String _kAutoLoginEnabled = 'ason_auto_login_enabled';
  static const String _kUserId = 'ason_user_id';
  static const String _kNickname = 'ason_nickname';
  static const String _kSessionId = 'ason_session_id';

  bool _isSessionActive = false;
  bool _autoLoginEnabled = false;
  String? _currentUserId;
  String? _currentNickname;

  /// 지금 실행 중인 앱에서 로그인된 상태인지 여부입니다. (재시작하면 초기화됩니다)
  bool get isSessionActive => _isSessionActive;

  /// 지금 로그인이 자동 로그인으로 유지되고 있는지 여부입니다.
  bool get autoLoginEnabled => _autoLoginEnabled;

  String? get currentUserId => _currentUserId;
  String? get currentNickname => _currentNickname;

  /// 테스트에서 각 테스트 사이에 상태를 초기화하기 위한 용도입니다.
  void resetForTest() {
    _isSessionActive = false;
    _autoLoginEnabled = false;
    _currentUserId = null;
    _currentNickname = null;
  }

  String _hash(String raw) => sha256.convert(utf8.encode(raw)).toString();

  String _newSessionId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<List<AsonAccount>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccounts);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AsonAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAccounts(List<AsonAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAccounts,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  /// 새 계정을 만듭니다. 아이디가 이미 있으면 실패합니다.
  Future<AuthResult> register({
    required String nickname,
    required String id,
    required String email,
    required String password,
  }) async {
    final accounts = await _loadAccounts();
    if (accounts.any((a) => a.id == id)) {
      return const AuthResult.failure('이미 사용 중인 아이디입니다.');
    }

    accounts.add(
      AsonAccount(
        nickname: nickname,
        id: id,
        email: email,
        passwordHash: _hash(password),
      ),
    );
    await _saveAccounts(accounts);
    return const AuthResult.success();
  }

  /// 아이디/비밀번호로 로그인합니다.
  /// [keepSignedIn]이 true일 때만 다음 실행에서도 로그인 상태가 이어집니다.
  Future<AuthResult> login({
    required String id,
    required String password,
    required bool keepSignedIn,
  }) async {
    final accounts = await _loadAccounts();
    AsonAccount? account;
    for (final a in accounts) {
      if (a.id == id) {
        account = a;
        break;
      }
    }

    if (account == null || account.passwordHash != _hash(password)) {
      return const AuthResult.failure('아이디 또는 비밀번호가 올바르지 않습니다.');
    }

    _isSessionActive = true;
    _autoLoginEnabled = keepSignedIn;
    _currentUserId = account.id;
    _currentNickname = account.nickname;

    if (keepSignedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setBool(_kAutoLoginEnabled, true);
      await prefs.setString(_kUserId, account.id);
      await prefs.setString(_kNickname, account.nickname);
      await prefs.setString(_kSessionId, _newSessionId());
    }

    return const AuthResult.success();
  }

  /// 앱 시작 시 한 번 호출합니다. 저장된 자동 로그인 정보가 있고 여전히
  /// 유효하면(계정이 실제로 존재하면) 로그인 상태로 만들어 줍니다.
  Future<AutoLoginResult> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    final autoLoginEnabled = prefs.getBool(_kAutoLoginEnabled) ?? false;
    final userId = prefs.getString(_kUserId);
    final nickname = prefs.getString(_kNickname);
    final sessionId = prefs.getString(_kSessionId);

    if (!isLoggedIn || !autoLoginEnabled || userId == null || sessionId == null) {
      return const AutoLoginResult.none();
    }

    final accounts = await _loadAccounts();
    final stillExists = accounts.any((a) => a.id == userId);
    if (!stillExists) {
      await _clearPersistedSession();
      return const AutoLoginResult.expired();
    }

    _isSessionActive = true;
    _autoLoginEnabled = true;
    _currentUserId = userId;
    _currentNickname = nickname;
    return const AutoLoginResult.success();
  }

  /// 자동 로그인 설정만 끕니다. 지금 실행 중인 로그인 세션은 유지되고,
  /// 다음 앱 실행부터 로그인 화면이 표시됩니다.
  Future<void> disableAutoLogin() async {
    _autoLoginEnabled = false;
    await _clearPersistedSession();
  }

  /// 로그아웃합니다. 지금 세션과 저장된 자동 로그인 정보를 모두 지웁니다.
  Future<void> logout() async {
    _isSessionActive = false;
    _autoLoginEnabled = false;
    _currentUserId = null;
    _currentNickname = null;
    await _clearPersistedSession();
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kAutoLoginEnabled);
    await prefs.remove(_kUserId);
    await prefs.remove(_kNickname);
    await prefs.remove(_kSessionId);
  }
}
