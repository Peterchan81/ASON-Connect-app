// ASON Connect의 핵심 흐름을 확인하는 스모크 테스트입니다.
// (Splash -> 자동 전환 -> ASON Connect 화면(입력 방식 선택 포함) -> 대화)
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
/// 로그인 화면과 무관하게 대화 기능만 검증하는 기존 테스트들이 곧바로
/// ASON Connect 화면으로 들어갈 수 있도록 사용합니다.
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

/// Splash는 자동 로그인 정보가 있어야 곧바로 ASON Connect 화면으로 넘어갑니다.
/// 대화 흐름 자체를 확인하는 테스트들은 로그인 화면부터 다시 검증할 필요가
/// 없으므로, 매 테스트마다 자동 로그인된 계정을 미리 만들어 둡니다.
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

/// Splash의 3초 자동 전환을 통과시키고, 입력 방식으로 "키보드 입력"을 골라
/// 곧바로 대화까지 진입합니다. 입력 방식은 이번 세션에서만 유지되며 기기에
/// 저장하지 않으므로, 매번 새로 골라야 합니다.
Future<void> _startChatInKeyboardMode(WidgetTester tester) async {
  await _seedAutoLogin();
  _usePhoneViewport(tester);
  // 로그인 화면을 거치지 않고 곧바로 대화 기능을 검증하기 위해, 이미
  // 자동 로그인된 상태로 시작합니다.
  SharedPreferences.setMockInitialValues(_autoLoggedInPrefs());
  await tester.pumpWidget(const AsonVoiceApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);

  await tester.tap(find.text('키보드 입력'));
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

  testWidgets('자동 로그인 정보가 저장되어 있으면 로그인 화면을 건너뛰고 ASON Connect 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    SharedPreferences.setMockInitialValues(_autoLoggedInPrefs());
    await tester.pumpWidget(const AsonVoiceApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(find.text('ASON Connect'), findsOneWidget);
    expect(find.text('Voice & Text Input'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    // 아직 입력 방식을 고른 적이 없으므로, 대화 화면 하단에 선택 UI가 먼저 나옵니다.
    expect(find.text('입력 방식을 선택하세요.'), findsOneWidget);
    expect(find.text('음성 입력'), findsOneWidget);
    expect(find.text('키보드 입력'), findsOneWidget);
  });

  testWidgets('입력 방식에서 키보드 입력을 고르면 곧바로 대화를 시작할 수 있다', (
    WidgetTester tester,
  ) async {
    await _startChatInKeyboardMode(tester);

    expect(find.text('입력 방식을 선택하세요.'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text(
        '안녕하세요.\n일정, 메모, 건강에 관한 내용을 말씀해 주세요.\nASON 통합 시스템에 정리해서 공유해 드리겠습니다.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('일정 대화: 부족한 정보(시간/내용/알림)를 사람처럼 한 번에 하나씩 묻는다', (
    WidgetTester tester,
  ) async {
    await _startChatInKeyboardMode(tester);

    // 시간/내용/장소가 모두 없는 문장 -> 장소는 강제로 묻지 않고, 시간부터 하나씩 묻습니다.
    await _sendText(tester, '미팅 있어');
    expect(find.text('몇 시 일정인가요?'), findsOneWidget);

    await _sendText(tester, '오후 5시');
    expect(find.text('일정 내용은 무엇인가요?'), findsOneWidget);

    await _sendText(tester, '팀 회의');
    expect(
      find.text('일정을 확인했습니다.\n알림을 설정하시겠습니까?\n예: 30분 전 알림'),
      findsOneWidget,
    );

    await _sendText(tester, '30분 전');

    // 큰 확인 카드 대신, 입력창 바로 위 컴팩트한 실시간 정리 패널에 나타납니다.
    expect(find.text('동기화 준비'), findsOneWidget);
    // "오후 5시"/"팀 회의"는 사용자의 답변 말풍선과 패널 값에 모두 나타납니다.
    expect(find.text('오후 5시'), findsWidgets);
    expect(find.text('팀 회의'), findsWidgets);
    expect(find.text('30분 전'), findsWidgets);
    expect(find.text('ASON Core에 동기화'), findsOneWidget);
  });

  testWidgets('일정 대화: 장소를 먼저 알아내고, 알림은 마지막에 단독으로 확인한 뒤 수정/동기화하면 초기화된다', (
    WidgetTester tester,
  ) async {
    await _startChatInKeyboardMode(tester);

    await _sendText(tester, '오늘 둔산동에서 일정 있어.');
    // 날짜/장소는 이미 알아냈으니 다시 묻지 않고, 시간부터 하나씩 묻습니다.
    expect(find.text('몇 시 일정인가요?'), findsOneWidget);

    await _sendText(tester, '오후 3시');
    expect(find.text('일정 내용은 무엇인가요?'), findsOneWidget);

    await _sendText(tester, '김 과장과 미팅');
    expect(
      find.text('일정을 확인했습니다.\n알림을 설정하시겠습니까?\n예: 30분 전 알림'),
      findsOneWidget,
    );

    await _sendText(tester, '30분 전');
    // 큰 확인 카드 대신, 입력창 바로 위 컴팩트한 실시간 정리 패널에 나타납니다.
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('오후 3시'), findsOneWidget);
    // "김 과장과 미팅"/"30분 전"은 사용자의 답변 말풍선과 패널 값에 모두 나타납니다.
    expect(find.text('김 과장과 미팅'), findsWidgets);
    expect(find.text('대전 둔산동'), findsOneWidget);
    expect(find.text('30분 전'), findsWidgets);
    expect(find.text('ASON Core에 동기화'), findsOneWidget);

    // 수정: 내용을 지우지 않고 무엇을 바꿀지 되묻는다.
    await tester.tap(find.text('수정'));
    await _settle(tester);
    expect(find.text('어떤 내용을 수정할까요?'), findsOneWidget);

    await _sendText(tester, '시간을 오후 4시로 바꿔줘.');
    expect(find.text('시간을 오후 4시로 변경했습니다.'), findsOneWidget);
    expect(find.text('오후 4시'), findsOneWidget);

    // 동기화: 로딩 표시(약 1초) -> 완료 문구 -> 새 내용 입력 버튼.
    await tester.tap(find.text('ASON Core에 동기화'));
    await tester.pump();
    expect(find.text('ASON Core에 동기화하는 중입니다...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await _settle(tester);
    expect(find.text('ASON Core에 동기화할 준비가 완료되었습니다.'), findsOneWidget);
    expect(find.text('새 내용 입력'), findsOneWidget);

    await tester.tap(find.text('새 내용 입력'));
    await _settle(tester);

    expect(
      find.text(
        '안녕하세요.\n일정, 메모, 건강에 관한 내용을 말씀해 주세요.\nASON 통합 시스템에 정리해서 공유해 드리겠습니다.',
      ),
      findsOneWidget,
    );
    expect(find.text('오후 4시'), findsNothing);
  });

  testWidgets('일정 대화: 수정 버튼을 눌러도 확인 카드가 사라지지 않고, 자연어로 항목을 하나씩 고칠 수 있다', (
    WidgetTester tester,
  ) async {
    await _startChatInKeyboardMode(tester);

    await _sendText(tester, '내일 오후 3시에 둔산동에서 김 과장과 미팅');
    // 시간/내용/장소가 모두 채워졌으니, 알림만 단독으로 확인합니다.
    expect(
      find.text('일정을 확인했습니다.\n알림을 설정하시겠습니까?\n예: 30분 전 알림'),
      findsOneWidget,
    );

    await _sendText(tester, '없음');
    // 큰 확인 카드 대신, 입력창 바로 위 컴팩트한 실시간 정리 패널에 나타납니다.
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('오후 3시'), findsOneWidget);
    expect(find.text('김 과장과 미팅'), findsOneWidget);
    expect(find.text('대전 둔산동'), findsOneWidget);

    // 수정 버튼을 눌러도 패널은 사라지지 않고, "수정" 버튼만 잠시 숨겨집니다.
    await tester.tap(find.text('수정'));
    await _settle(tester);
    expect(find.text('수정 가능'), findsOneWidget);
    expect(find.text('김 과장과 미팅'), findsOneWidget);
    expect(find.text('수정'), findsNothing);

    // 자연어로 장소를 고칩니다: "장소는 유성구"
    await _sendText(tester, '장소는 유성구');
    expect(find.text('유성구'), findsWidgets);
    expect(find.text('수정'), findsOneWidget);

    // 내용을 고칩니다: "내용은 인테리어 미팅으로 변경"
    await tester.tap(find.text('수정'));
    await _settle(tester);
    await _sendText(tester, '내용은 인테리어 미팅으로 변경');
    expect(find.text('인테리어 미팅'), findsWidgets);

    // 알림을 끕니다: "알림 없어" -> "없음"으로 정리됩니다.
    await tester.tap(find.text('수정'));
    await _settle(tester);
    await _sendText(tester, '알림 없어');
    expect(find.text('없음'), findsWidgets);

    // 메모를 채웁니다: "메모에 계약서 준비"
    await tester.tap(find.text('수정'));
    await _settle(tester);
    await _sendText(tester, '메모에 계약서 준비');
    expect(find.text('계약서 준비'), findsWidgets);

    // 반복을 설정합니다: "반복은 매주 월요일"
    await tester.tap(find.text('수정'));
    await _settle(tester);
    await _sendText(tester, '반복은 매주 월요일');
    expect(find.text('매주 월요일'), findsWidgets);
  });

  testWidgets('입력 방식은 작은 버튼으로 음성/키보드 사이를 즉시 전환할 수 있다', (
    WidgetTester tester,
  ) async {
    await _startChatInKeyboardMode(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('음성으로 변경'), findsOneWidget);

    await tester.tap(find.text('음성으로 변경'));
    await _settle(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('키보드로 변경'), findsOneWidget);

    await tester.tap(find.text('키보드로 변경'));
    await _settle(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('건강 대화: 혈압 수치를 바로 인식해서 정리한다', (WidgetTester tester) async {
    await _startChatInKeyboardMode(tester);

    await _sendText(tester, '오늘 혈압이 128에 82야.');

    // 큰 확인 카드 대신, 입력창 바로 위 컴팩트한 실시간 정리 패널에 나타납니다.
    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('혈압'), findsOneWidget);
    expect(find.text('128 / 82 mmHg'), findsOneWidget);
  });

  testWidgets('메모 대화: 구매 표현을 자연스러운 문장으로 정리한다', (WidgetTester tester) async {
    await _startChatInKeyboardMode(tester);

    await _sendText(tester, '우유하고 계란 사야 해');

    expect(find.text('동기화 준비'), findsOneWidget);
    expect(find.text('우유와 계란 구매'), findsOneWidget);
  });

  testWidgets('ASON과 관계없는 일반 대화는 자연스럽게 기록을 제안한다', (WidgetTester tester) async {
    await _startChatInKeyboardMode(tester);

    await _sendText(tester, '오늘 기분이 별로야');

    expect(
      find.text('오늘 컨디션이 좋지 않으셨군요.\n이 내용을 건강 기록이나 메모로 정리할까요?'),
      findsOneWidget,
    );
    expect(find.text('ASON Core에 동기화'), findsNothing);
  });
}
