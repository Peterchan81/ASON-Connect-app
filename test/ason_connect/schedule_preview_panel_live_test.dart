// 입력창 바로 위 실시간 정리 패널이 (1) 전송 전에는 미리보기로, (2) 전송
// 후에는 컴팩트한 카드로 나타나고 큰 확인 카드가 채팅을 가리지 않는지
// 확인합니다.

import 'package:ason_voice_app/app.dart';
import 'package:ason_voice_app/features/auth/services/auth_service.dart';
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

Future<void> _startChatInKeyboardMode(WidgetTester tester) async {
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
    keepSignedIn: true,
  );

  _usePhoneViewport(tester);
  await tester.pumpWidget(const AsonVoiceApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);

  await tester.tap(find.text('키보드 입력'));
  await _settle(tester);
}

void main() {
  testWidgets('전송하기 전에도 입력창 바로 위에 실시간 미리보기가 컴팩트하게 나타난다', (
    tester,
  ) async {
    await _startChatInKeyboardMode(tester);

    await tester.enterText(find.byType(TextField), '내일 오후 3시 영동에서 광고미팅');
    // 실시간 분석은 debounce(350ms) 이후에 반영됩니다.
    await tester.pump(const Duration(milliseconds: 500));

    // 아직 전송하지 않았으므로 "분석 중" 미리보기 상태이고, 확정 안내 문구가 보입니다.
    expect(find.text('분석 중'), findsOneWidget);
    expect(find.text('Enter를 누르거나 전송하면 확정됩니다.'), findsOneWidget);
    // 미리보기 단계에서는 수정/동기화 버튼을 아직 제공하지 않습니다.
    expect(find.text('ASON Core에 동기화'), findsNothing);
    // 채팅 목록은 여전히 온전히 보입니다(전송 전이라 아직 메시지가 추가되지 않음).
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('전송하면 미리보기가 실제 정리 패널로 바뀌고 채팅도 그대로 보인다', (tester) async {
    await _startChatInKeyboardMode(tester);

    await tester.enterText(find.byType(TextField), '내일 오후 3시 영동에서 광고미팅');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '없음');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _settle(tester);

    // 큰 카드가 채팅을 덮지 않고, 사용자가 보낸 원문 말풍선이 여전히 보입니다.
    expect(find.textContaining('내일 오후 3시 영동에서 광고미팅'), findsOneWidget);
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('ASON Core에 동기화'), findsOneWidget);
  });
}
