// ASON Connect V2 지시서(섹션 18)에 명시된 6개의 필수 테스트 문장입니다.
// 각 문장이 올바른 종류(일정/나의 하루 목표/다이어리/메모)로 자동 분류되고,
// 여러 의도가 섞인 문장은 항목별로 나뉘며, 알림/반복 같은 표현이 내용 필드에
// 섞여 들어가지 않는지 확인합니다.

import 'dart:convert';

import 'package:ason_voice_app/app.dart';
import 'package:ason_voice_app/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> _autoLoggedInPrefs() => {
  'ason_is_logged_in': true,
  'ason_auto_login_enabled': true,
  'ason_user_id': 'test_user',
  'ason_nickname': '테스트',
  'ason_session_id': 'test_session',
  'ason_accounts': jsonEncode([
    {
      'nickname': '테스트',
      'id': 'test_user',
      'email': 'test@ason.app',
      'passwordHash': 'x',
    },
  ]),
};

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

Future<void> _startConnect(WidgetTester tester) async {
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
  SharedPreferences.setMockInitialValues(_autoLoggedInPrefs());
  await tester.pumpWidget(const AsonVoiceApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);

  await tester.tap(find.text('문자로 입력하기'));
  await _settle(tester);
}

Future<void> _sendText(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send_rounded));
  await _settle(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('테스트 1: 일정 문장은 알림까지 하나의 일정 카드로 정리된다', (tester) async {
    await _startConnect(tester);

    // 입력창은 한 줄 텍스트만 받으므로, 지시서의 줄바꿈은 실제로는 한 문장
    // 안에서 쉼표로 이어 말하는 것과 같습니다.
    await _sendText(tester, '내일 영동에서 오후 3시 광고미팅, 한 시간 전에 알려줘.');

    expect(find.text('일정'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('오후 3시'), findsOneWidget);
    expect(find.text('광고미팅'), findsOneWidget);
    expect(find.text('영동'), findsOneWidget);
    expect(find.text('1시간 전'), findsOneWidget);
    expect(find.text('나의 하루 목표'), findsNothing);
  });

  testWidgets('테스트 2: 반복 습관 문장은 나의 하루 목표 카드 1개로 정리된다', (tester) async {
    await _startConnect(tester);

    await _sendText(tester, '매일 아침 스트레칭하기.');

    expect(find.text('나의 하루 목표'), findsOneWidget);
    expect(find.text('스트레칭'), findsOneWidget);
    expect(find.text('매일 아침'), findsOneWidget);
    expect(find.text('일정'), findsNothing);
  });

  testWidgets('테스트 3: 쉼표 없이 이어 말한 문장도 일정과 나의 하루 목표 두 개의 카드로 나뉜다', (
    tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '내일 오후 3시 광고미팅하고 한 시간 전에 알려주고 매일 아침 스트레칭하기.');

    expect(find.text('일정'), findsOneWidget);
    expect(find.text('나의 하루 목표'), findsOneWidget);
    // "-고" 연결형이 자연스러운 "-기" 종결형으로 정리됩니다.
    expect(find.text('광고미팅하기'), findsOneWidget);
    expect(find.text('1시간 전'), findsOneWidget);
    expect(find.text('스트레칭'), findsOneWidget);
    expect(find.text('매일 아침'), findsOneWidget);
    // "매일 아침 스트레칭"이 일정 쪽 내용/알림에 섞여 들어가지 않습니다.
    expect(find.textContaining('스트레칭하기'), findsNothing);
    expect(find.text('모두 ASON에 동기화'), findsOneWidget);
  });

  testWidgets('테스트 4: 감정/하루 기록 문장은 다이어리 카드 1개로 정리된다', (tester) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 가족과 여행해서 즐거웠다.');

    expect(find.text('다이어리'), findsOneWidget);
    expect(find.text('오늘 가족과 여행해서 즐거웠다'), findsOneWidget);
    expect(find.text('일정'), findsNothing);
  });

  testWidgets('테스트 5: 날짜/실행 시간이 없는 기록은 메모 카드 1개로 정리된다', (tester) async {
    await _startConnect(tester);

    await _sendText(tester, '회의 아이디어 정리해 두기.');

    expect(find.text('메모'), findsOneWidget);
    expect(find.text('일정'), findsNothing);
    expect(find.text('나의 하루 목표'), findsNothing);
  });

  // ASON Connect는 입력 폼이 아닙니다: 시간처럼 부족한 항목이 있어도 "몇 시인가요?"
  // 처럼 하나씩 되묻지 않고, 곧바로 결과 카드를 보여줍니다. 빈 항목은 카드에
  // 빈 채로 표시되고, 사용자가 수정 버튼으로 채웁니다.
  testWidgets('테스트 6: 날짜만 있고 시간이 없는 일정도 되묻지 않고 곧바로 결과 카드가 보인다', (tester) async {
    await _startConnect(tester);

    await _sendText(tester, '내일 광고미팅 있어.');

    expect(find.text('몇 시 일정인가요?'), findsNothing);
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('ASON에 동기화'), findsOneWidget);
  });
}
