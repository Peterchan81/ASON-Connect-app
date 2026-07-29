// 로그인/회원가입 화면의 실제 사용자 흐름을 검증합니다.
// (빈 값 검증, 잘못된 로그인, 로그인 성공 후 뒤로 가기 방지, 회원가입 검증,
//  로그아웃 후 뒤로 가기 방지)

import 'package:ason_voice_app/features/ason_connect/screens/ason_connect_screen.dart';
import 'package:ason_voice_app/features/auth/screens/login_screen.dart';
import 'package:ason_voice_app/features/auth/screens/signup_screen.dart';
import 'package:ason_voice_app/features/auth/services/auth_service.dart';
import 'package:ason_voice_app/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.resetForTest();
  });

  testWidgets('빈 값으로 로그인을 누르면 화면 안에 오류가 표시되고 로그인 화면에 그대로 머문다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await _settle(tester);

    await tester.tap(find.text('ASON 시작하기'));
    await _settle(tester);

    expect(find.text('아이디를 입력해주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('등록되지 않은 계정으로 로그인하면 화면 안에 오류 메시지가 보인다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).at(0), 'nobody');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.text('ASON 시작하기'));
    await _settle(tester);

    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('올바른 계정으로 로그인하면 메인 화면으로 이동하고, 뒤로 가기로 로그인 화면에 돌아갈 수 없다', (
    tester,
  ) async {
    await AuthService.instance.register(
      nickname: '테스터',
      id: 'tester',
      email: 'tester@ason.app',
      password: 'pw1234',
    );

    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).at(0), 'tester');
    await tester.enterText(find.byType(TextField).at(1), 'pw1234');
    await tester.tap(find.text('ASON 시작하기'));
    await _settle(tester);

    expect(find.byType(AsonConnectScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('회원가입 화면에서 비밀번호 확인이 다르면 오류가 표시되고 가입되지 않는다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).at(0), '닉네임');
    await tester.enterText(find.byType(TextField).at(1), 'newuser');
    await tester.enterText(find.byType(TextField).at(2), 'pw1234');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.enterText(find.byType(TextField).at(4), 'newuser@ason.app');
    await tester.ensureVisible(find.text('회원가입 완료'));
    await tester.tap(find.text('회원가입 완료'));
    await _settle(tester);

    expect(find.text('비밀번호가 일치하지 않습니다.'), findsOneWidget);
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('회원가입 화면에서 필수 약관에 동의하지 않으면 오류가 표시된다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).at(0), '닉네임');
    await tester.enterText(find.byType(TextField).at(1), 'newuser');
    await tester.enterText(find.byType(TextField).at(2), 'pw1234');
    await tester.enterText(find.byType(TextField).at(3), 'pw1234');
    await tester.enterText(find.byType(TextField).at(4), 'newuser@ason.app');
    await tester.ensureVisible(find.text('회원가입 완료'));
    await tester.tap(find.text('회원가입 완료'));
    await _settle(tester);

    expect(find.text('필수 약관에 동의해주세요.'), findsOneWidget);
  });

  testWidgets('회원가입을 마치면 로그인 화면을 다시 거치지 않고 곧바로 Connect 입력 화면으로 이동한다', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await _settle(tester);

    await tester.tap(find.text('회원가입'));
    await _settle(tester);
    expect(find.byType(SignupScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '새사용자');
    await tester.enterText(find.byType(TextField).at(1), 'newuser');
    await tester.enterText(find.byType(TextField).at(2), 'pw1234');
    await tester.enterText(find.byType(TextField).at(3), 'pw1234');
    await tester.enterText(find.byType(TextField).at(4), 'newuser@ason.app');
    await tester.ensureVisible(find.text('전체 동의'));
    await tester.tap(find.text('전체 동의'));
    await _settle(tester);
    await tester.ensureVisible(find.text('회원가입 완료'));
    await tester.tap(find.text('회원가입 완료'));
    await _settle(tester);

    expect(find.byType(SignupScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AsonConnectScreen), findsOneWidget);
    expect(AuthService.instance.isSessionActive, isTrue);
    expect(AuthService.instance.autoLoginEnabled, isTrue);

    // 뒤로 가기로 회원가입/로그인 화면에 돌아갈 수 없습니다.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('메인 화면에서 로그아웃하면 로그인 화면으로 이동하고, 뒤로 가기로 메인 화면에 돌아갈 수 없다', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: AsonConnectScreen()));
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await _settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
    await _settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AsonConnectScreen), findsNothing);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
  });
}
