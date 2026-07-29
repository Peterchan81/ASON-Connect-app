// ASON Connect의 핵심 흐름을 확인하는 스모크 테스트입니다.
// (Splash -> 자동 로그인 확인 -> 곧바로 Connect 입력 화면 -> 분석/수정/동기화)
//
// ASON Connect는 종류를 먼저 고르는 선택 화면이나 채팅 이력 없이, 입력창
// 하나와 그 위의 컴팩트한 정리 패널만으로 동작합니다.
//
// 마이크 버튼의 Pulse, 배경의 Glow 등 화면에는 의도적으로 끝나지 않는(반복) 애니메이션이
// 있어 pumpAndSettle()을 사용하면 타임아웃이 발생합니다. 대신 전환/등장 애니메이션이
// 끝나기에 충분한 만큼만 정해진 시간으로 프레임을 진행하는 _settle()을 사용합니다.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ason_voice_app/app.dart';
import 'package:ason_voice_app/features/auth/services/auth_service.dart';

/// AuthService가 저장하는 형태와 동일한, 이미 로그인/자동 로그인된 상태입니다.
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

/// 기본 테스트 화면(800x600, 가로형)은 실제 휴대폰 화면비와 달라 세로 공간이
/// 지나치게 좁습니다. 일반적인 휴대폰 세로 화면 크기로 바꿔서 테스트합니다.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _seedAutoLogin() async {
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
}

/// Splash의 3초 자동 전환을 통과시켜, 곧바로 Connect 입력 화면으로 진입합니다.
/// 종류/입력 방식을 먼저 고르는 단계가 없으므로, 진입하자마자 입력할 수 있습니다.
Future<void> _launchConnect(WidgetTester tester) async {
  await _seedAutoLogin();
  _usePhoneViewport(tester);
  SharedPreferences.setMockInitialValues(_autoLoggedInPrefs());
  await tester.pumpWidget(const AsonVoiceApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);
}

Future<void> _startConnect(WidgetTester tester) async {
  await _launchConnect(tester);

  // 첫 화면은 큰 선택 버튼 두 개만 보여줍니다. "문자로 입력하기"를 골라야
  // 입력창이 나타납니다.
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
    // ASON-Core 데이터 구조 동기화(core_sync)가 SharedPreferences를 사용하므로
    // 위젯 테스트에서도 실제 플랫폼 채널 대신 메모리 목(mock)을 사용합니다.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash 화면이 표시된 뒤 3초 후, 저장된 로그인 정보가 없으면 로그인 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    // 저장된 자동 로그인 정보가 전혀 없는, 최초 실행 상태를 재현합니다.
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.resetForTest();
    _usePhoneViewport(tester);
    await tester.pumpWidget(const AsonVoiceApp());
    await tester.pump();

    // "ASON" 로고는 Glow 2겹 + 속 채움 1겹 + 그라디언트 외곽선 1겹, 네 겹의
    // Text로 그려집니다.
    expect(find.text('ASON'), findsNWidgets(4));
    expect(find.text('CONNECT'), findsOneWidget);
    expect(find.text('잠시 후 시작됩니다.'), findsOneWidget);
    // 카운트다운 숫자도 Glow + 속 채움 + 그라디언트 외곽선, 세 겹입니다.
    expect(find.text('3'), findsNWidgets(3));

    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    // 최초 실행(자동 로그인 정보 없음) -> ASON Connect 화면이 아니라 로그인 화면으로 이동합니다.
    expect(find.text('ASON 시작하기'), findsOneWidget);
    expect(find.text('로그인하고 나만의 ASON을 만나보세요.'), findsOneWidget);
    expect(find.text('ASON Connect'), findsNothing);
  });

  testWidgets('자동 로그인 정보가 있으면 기능 선택 없이 곧바로 Connect 입력 방식 선택 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    await _launchConnect(tester);

    expect(find.text('ASON Connect'), findsOneWidget);
    expect(find.text('Voice & Text Input'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    // 카테고리/기능을 먼저 고르는 화면은 없고, 음성/문자 중 어떻게 입력할지
    // 고르는 크고 명확한 버튼 두 개와 안내 문구만 보입니다.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('음성으로 말하기'), findsOneWidget);
    expect(find.text('문자로 입력하기'), findsOneWidget);
    expect(find.text('생각하지 말고 말하세요.\nASON이 정리합니다.'), findsOneWidget);

    // "문자로 입력하기"를 고르면 곧바로 입력창이 나타납니다.
    await tester.tap(find.text('문자로 입력하기'));
    await _settle(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('일정 대화: 정보가 부족해도 하나씩 되묻지 않고 곧바로 컴팩트 카드가 보인다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    // 시간/내용이 모두 없는 문장이라도, 입력 폼처럼 되묻지 않고 곧바로
    // 결과 카드가 나타납니다. 빈 항목은 카드에 빈 채로 표시됩니다.
    await _sendText(tester, '미팅 있어');

    expect(find.text('몇 시 일정인가요?'), findsNothing);
    expect(find.text('일정 내용은 무엇인가요?'), findsNothing);
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('ASON에 동기화'), findsOneWidget);
  });

  testWidgets('일정 대화: 한 문장에 정보가 다 있으면 곧바로 컴팩트 카드가 보인다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오후 5시 팀 회의');

    // 큰 카드가 아니라, 입력창 바로 위 컴팩트한 실시간 정리 패널에 나타납니다.
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('오후 5시'), findsOneWidget);
    expect(find.text('팀 회의'), findsOneWidget);
    expect(find.text('ASON에 동기화'), findsOneWidget);
    // 반복이 없으면 "반복" 항목 자체를 표시하지 않습니다.
    expect(find.text('반복'), findsNothing);
  });

  testWidgets('일정 대화: 수정 후 동기화하면 짧게 안내하고 입력창과 카드를 초기화한다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 오후 3시 둔산동에서 김 과장과 미팅.');
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('오후 3시'), findsOneWidget);
    expect(find.text('김 과장과 미팅'), findsOneWidget);
    expect(find.text('대전 둔산동'), findsOneWidget);

    // 수정: 내용을 지우지 않고 무엇을 바꿀지 되묻는다.
    await tester.tap(find.text('수정'));
    await _settle(tester);
    expect(find.text('어떤 내용을 수정할까요?'), findsOneWidget);

    await _sendText(tester, '시간을 오후 4시로 바꿔줘.');
    expect(find.text('오후 4시'), findsOneWidget);

    // 동기화: 로딩 표시(약 1초) -> 짧은 완료 안내 -> 입력창/카드 초기화.
    await tester.tap(find.text('ASON에 동기화'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1100));
    await _settle(tester);

    expect(find.text('ASON에 저장되었습니다.'), findsOneWidget);
    expect(find.text('동기화 준비'), findsNothing);
    expect(find.text('오후 4시'), findsNothing);
    // 동기화가 끝나면 다음 입력을 받을 수 있도록 처음 선택 화면으로 되돌아갑니다.
    expect(find.text('생각하지 말고 말하세요.\nASON이 정리합니다.'), findsOneWidget);
    expect(find.text('음성으로 말하기'), findsOneWidget);
  });

  testWidgets('입력 중에는 아이콘만 있는 작은 전환 버튼이 아니라, 명확한 텍스트 버튼으로 음성/문자를 즉시 전환할 수 있다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('음성으로 입력하기'), findsOneWidget);

    await tester.tap(find.text('음성으로 입력하기'));
    await _settle(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('문자로 입력하기'), findsOneWidget);

    await tester.tap(find.text('문자로 입력하기'));
    await _settle(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('건강 대화: 혈압 수치를 바로 인식해서 컴팩트 카드로 정리한다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 혈압이 128에 82야.');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('혈압'), findsOneWidget);
    expect(find.text('128 / 82 mmHg'), findsOneWidget);
  });

  testWidgets('메모 대화: 구매 표현을 자연스러운 문장으로 정리한다', (WidgetTester tester) async {
    await _startConnect(tester);

    await _sendText(tester, '우유하고 계란 사야 해');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('우유와 계란 구매'), findsOneWidget);
  });

  testWidgets('다이어리 대화: 감정/하루 기록은 종류를 먼저 묻지 않고 다이어리로 자동 정리한다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 기분이 별로야');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('다이어리'), findsOneWidget);
    expect(find.text('오늘 기분이 별로야'), findsOneWidget);
    expect(find.text('ASON에 동기화'), findsOneWidget);
  });

  testWidgets('ASON의 4가지 분류 어디에도 해당하지 않는 일반 대화는 동기화 버튼을 보여주지 않는다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 피곤해');

    expect(
      find.text('오늘 컨디션이 좋지 않으셨군요.\n이 내용을 건강 기록이나 메모로 정리할까요?'),
      findsOneWidget,
    );
    expect(find.text('ASON에 동기화'), findsNothing);
  });

  testWidgets('나의 하루 목표 대화: 반복 습관을 종류를 먼저 묻지 않고 목표로 자동 정리한다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '매일 아침 스트레칭하기.');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('나의 하루 목표'), findsOneWidget);
    expect(find.text('스트레칭'), findsOneWidget);
    expect(find.text('매일 아침'), findsOneWidget);
  });

  testWidgets('일정 대화: 알림/반복이 문장에 함께 있으면 내용에 섞이지 않고 각각의 항목으로 분리된다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '내일 영동 3시 광고미팅 알람 1시간 전 반복 없음');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('오후 3시'), findsOneWidget);
    expect(find.text('광고미팅'), findsOneWidget);
    expect(find.text('영동'), findsOneWidget);
    expect(find.text('1시간 전'), findsOneWidget);
  });

  testWidgets('여러 의도 분리: 일정과 나의 하루 목표가 섞인 문장은 두 개의 카드로 나뉜다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '내일 영동에서 3시 광고미팅, 한 시간 전에 알려주고, 매일 아침 스트레칭하기.');

    // 하나의 일정으로 통째로 저장되지 않고, 일정/나의 하루 목표 두 개의 카드로 나뉩니다.
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('나의 하루 목표'), findsOneWidget);
    expect(find.text('광고미팅'), findsOneWidget);
    expect(find.text('영동'), findsOneWidget);
    expect(find.text('1시간 전'), findsOneWidget);
    expect(find.text('스트레칭'), findsOneWidget);
    expect(find.text('매일 아침'), findsOneWidget);
    // "매일 아침 스트레칭"이 일정의 알림 항목에 섞여 들어가지 않습니다.
    expect(find.text('1시간 전, 매일 아침'), findsNothing);
    // 두 항목 모두 준비되었으므로 "모두 ASON에 동기화" 버튼이 나타납니다.
    expect(find.text('모두 ASON에 동기화'), findsOneWidget);
  });

  testWidgets('여러 의도 분리: 다이어리와 메모가 섞인 문장은 두 개의 카드로 나뉜다', (
    WidgetTester tester,
  ) async {
    await _startConnect(tester);

    await _sendText(tester, '오늘 가족과 여행 가서 기분이 좋았다, 우유하고 계란 사야 해.');

    expect(find.text('다이어리'), findsOneWidget);
    expect(find.text('메모'), findsOneWidget);
    expect(find.text('오늘 가족과 여행 가서 기분이 좋았다'), findsOneWidget);
    expect(find.text('우유와 계란 구매'), findsOneWidget);
    expect(find.text('모두 ASON에 동기화'), findsOneWidget);
  });
}
