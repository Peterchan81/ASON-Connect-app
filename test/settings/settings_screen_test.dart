// 설정 화면의 핵심 동작을 확인합니다.
// (닉네임 변경, 알림 설정 저장, 테마 선택 저장, 로그아웃 취소/확정)

import 'package:ason_voice_app/features/auth/services/auth_service.dart';
import 'package:ason_voice_app/features/settings/screens/settings_screen.dart';
import 'package:ason_voice_app/features/settings/services/settings_service.dart';
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.resetForTest();
    await AuthService.instance.register(
      nickname: '테스터',
      id: 'tester',
      email: 'tester@ason.app',
      password: 'pw1234',
    );
    await AuthService.instance.login(
      id: 'tester',
      password: 'pw1234',
      keepSignedIn: false,
    );
  });

  testWidgets('계정 정보에 아이디/이메일이 읽기 전용으로 표시되고, 닉네임만 저장할 수 있다', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await _settle(tester);

    expect(find.text('tester'), findsOneWidget);
    expect(find.text('tester@ason.app'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '새닉네임');
    await tester.tap(find.text('저장'));
    await _settle(tester);

    expect(find.text('닉네임이 변경되었습니다.'), findsOneWidget);
    expect(AuthService.instance.currentNickname, '새닉네임');
  });

  testWidgets('알림 스위치를 끄면 SettingsService에도 저장된다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await _settle(tester);

    await tester.ensureVisible(find.text('일정'));
    await tester.tap(find.text('일정'));
    await _settle(tester);

    final enabled = await SettingsService.instance.loadNotificationEnabled(
      NotificationCategory.schedule,
    );
    expect(enabled, isFalse);
  });

  testWidgets('테마에서 라이트 모드를 고르면 저장된다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await _settle(tester);

    await tester.ensureVisible(find.text('라이트 모드'));
    await tester.tap(find.text('라이트 모드'));
    await _settle(tester);

    final mode = await SettingsService.instance.loadThemeMode();
    expect(mode, AppThemeMode.light);
  });

  testWidgets('로그아웃 확인 다이얼로그에서 취소하면 설정 화면에 그대로 머문다', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await _settle(tester);

    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await _settle(tester);

    await tester.tap(find.text('취소'));
    await _settle(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(AuthService.instance.isSessionActive, isTrue);
  });
}
