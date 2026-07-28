// AuthService의 회원가입/로그인/자동 로그인/로그아웃/세션 만료 처리를 검증합니다.

import 'package:ason_voice_app/features/auth/models/auth_result.dart';
import 'package:ason_voice_app/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.resetForTest();
  });

  Future<void> registerTestUser({String id = 'tester', String password = 'pw1234'}) {
    return AuthService.instance
        .register(nickname: '테스터', id: id, email: 'tester@ason.app', password: password)
        .then((_) {});
  }

  test('회원가입 후 올바른 정보로 로그인하면 성공한다', () async {
    await registerTestUser();

    final result = await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: false,
    );

    expect(result.isSuccess, isTrue);
    expect(AuthService.instance.isSessionActive, isTrue);
    expect(AuthService.instance.currentUserId, 'tester');
  });

  test('같은 아이디로 다시 회원가입하면 실패한다', () async {
    await registerTestUser();
    final result = await AuthService.instance.register(
      nickname: '다른닉네임',
      id: 'tester',
      email: 'other@ason.app',
      password: 'pw5678',
    );

    expect(result.isSuccess, isFalse);
  });

  test('비밀번호가 틀리면 로그인에 실패한다', () async {
    await registerTestUser();

    final result = await AuthService.instance.login(
      id: 'tester',
      password: 'wrong-password',
      keepSignedIn: false,
    );

    expect(result.isSuccess, isFalse);
    expect(AuthService.instance.isSessionActive, isFalse);
  });

  test('등록되지 않은 아이디로 로그인하면 실패한다', () async {
    final result = await AuthService.instance.login(
      id: 'nobody',
      password: 'pw1234',
      keepSignedIn: false,
    );

    expect(result.isSuccess, isFalse);
  });

  test('최초 실행(저장된 정보 없음) -> 자동 로그인은 none이다', () async {
    final result = await AuthService.instance.tryAutoLogin();
    expect(result.status, AutoLoginStatus.none);
  });

  test('자동 로그인을 선택하지 않고 로그인하면, 앱을 재시작한 것처럼 다시 확인했을 때 로그인 화면으로 간다', () async {
    await registerTestUser();
    final loginResult = await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: false,
    );
    expect(loginResult.isSuccess, isTrue);
    expect(AuthService.instance.isSessionActive, isTrue); // 현재 실행 중에는 유지

    // 앱 재시작을 흉내 냅니다. (메모리 상태만 초기화, 저장된 값은 그대로)
    AuthService.instance.resetForTest();

    final autoLogin = await AuthService.instance.tryAutoLogin();
    expect(autoLogin.status, AutoLoginStatus.none);
  });

  test('자동 로그인을 선택하고 로그인하면, 앱을 재시작해도 자동으로 로그인된다', () async {
    await registerTestUser();
    await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: true,
    );

    AuthService.instance.resetForTest(); // 앱 재시작 흉내

    final autoLogin = await AuthService.instance.tryAutoLogin();
    expect(autoLogin.isSuccess, isTrue);
    expect(AuthService.instance.currentUserId, 'tester');
  });

  test('저장된 자동 로그인 정보가 있어도 계정이 더 이상 존재하지 않으면 만료로 처리하고 정보를 지운다', () async {
    await registerTestUser();
    await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: true,
    );

    // 계정 저장소가 손상/초기화된 상황을 흉내 냅니다.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ason_accounts');
    AuthService.instance.resetForTest();

    final autoLogin = await AuthService.instance.tryAutoLogin();
    expect(autoLogin.status, AutoLoginStatus.expired);

    // 손상된 자동 로그인 정보는 정리되어, 다시 확인해도 로그인 화면(none)으로 간다.
    final again = await AuthService.instance.tryAutoLogin();
    expect(again.status, AutoLoginStatus.none);
  });

  test('로그아웃하면 세션과 저장된 자동 로그인 정보가 모두 사라진다', () async {
    await registerTestUser();
    await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: true,
    );

    await AuthService.instance.logout();
    expect(AuthService.instance.isSessionActive, isFalse);

    AuthService.instance.resetForTest();
    final autoLogin = await AuthService.instance.tryAutoLogin();
    expect(autoLogin.status, AutoLoginStatus.none);
  });

  test('자동 로그인만 해제하면, 지금 세션은 유지되지만 다음 실행부터는 로그인 화면으로 간다', () async {
    await registerTestUser();
    await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: true,
    );

    await AuthService.instance.disableAutoLogin();
    expect(AuthService.instance.isSessionActive, isTrue); // 지금 세션은 유지

    AuthService.instance.resetForTest(); // 다음 실행 흉내
    final autoLogin = await AuthService.instance.tryAutoLogin();
    expect(autoLogin.status, AutoLoginStatus.none);
  });
}
