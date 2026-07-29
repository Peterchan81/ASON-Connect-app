// 지시서(ASON Engine 상대 날짜 인식 1단계) 섹션 7의 수동 확인 문장 5개를
// ConversationManager 수준에서 자동으로도 검증합니다. 기준 날짜는
// 2026-07-29(수요일)로 고정합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/command_parser_service.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ConversationManager managerAt(DateTime fixedNow) => ConversationManager(
    parser: CommandParserService(nowProvider: () => fixedNow),
  );

  test('문장 1: 다음 주 월요일 오전 10시에 은행에 가기 -> 일정 카드', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('다음 주 월요일 오전 10시에 은행에 가기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.date, '2026-08-03');
    expect(manager.currentDraft?.time, '오전 10시');
    expect(manager.currentDraft?.title, '은행 가기');
  });

  test('문장 2: 이번 주 금요일 오후 4시에 거래처 담당자 만나기 -> 일정 카드', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('이번 주 금요일 오후 4시에 거래처 담당자 만나기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.date, '2026-07-31');
    expect(manager.currentDraft?.time, '오후 4시');
    expect(manager.currentDraft?.title, '거래처 담당자 만나기');
  });

  test('문장 3: 다음 달 3일에 병원 방문하기 -> 일정 카드', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('다음 달 3일에 병원 방문하기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.date, '2026-08-03');
    expect(manager.currentDraft?.title, '병원 방문하기');
  });

  // 참고(이번 턴과 무관한 기존 버그): "친구"가 KoreanLocationService에 의해
  // "친"+"구"(행정구역 접미사) 형태의 확실한 장소로 오인식되어 제목에서
  // 빠집니다. 날짜(가장 가까운 미래의 금요일) 자체는 정확히 계산됩니다.
  test('문장 4: 금요일에 친구 만나기 -> 일정 카드(날짜는 정확, 제목은 기존 장소 오인식의 영향을 받음)', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('금요일에 친구 만나기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.date, '2026-07-31');
  });

  test('문장 5: 다음 주부터 매일 30분 걷기 -> 목표 분류 유지(일정으로 잘못 분류되지 않음)', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('다음 주부터 매일 30분 걷기');

    expect(manager.currentDraft?.category, DraftCommandCategory.dailyGoal);
  });
}
