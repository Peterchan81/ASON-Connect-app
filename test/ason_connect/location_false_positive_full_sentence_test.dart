// 지시서(ASON Engine 자연어 이해 2단계) 섹션 8D의 전체 문장 테스트 6개입니다.
// 장소 오인식 방지가 실제 대화 흐름(분류/날짜/장소/제목)에 올바르게
// 반영되는지 ConversationManager 수준에서 검증합니다. 기준 날짜는
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

  test('1. 금요일에 친구 만나기 -> 일정, 날짜 추출, 장소 없음, 내용: 친구 만나기', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('금요일에 친구 만나기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.date, '2026-07-31');
    expect(manager.currentDraft?.location, isNull);
    expect(manager.currentDraft?.title, '친구 만나기');
  });

  // 이 문장은 지시서에서도 "일정 또는 기존 정책에 맞는 카드"로 결과를
  // 유연하게 허용합니다. 이 턴에서 반드시 지켜야 할 것은 장소가 더 이상
  // "야구"로 잘못 채워지지 않는 것과, 제목에 "야구"가 그대로 남는 것입니다.
  test('2. 내일 야구 연습하기 -> 장소 없음, 제목에 "야구" 유지', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('내일 야구 연습하기');

    expect(manager.currentDraft, isNotNull);
    expect(manager.currentDraft?.location, isNull);
    expect(manager.currentDraft?.title, contains('야구'));
  });

  test('3. 내일 중구에서 친구 만나기 -> 일정, 장소: 중구, 내용: 친구 만나기', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('내일 중구에서 친구 만나기');

    expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    expect(manager.currentDraft?.location, '중구');
    expect(manager.currentDraft?.title, '친구 만나기');
  });

  test(
    '4. 다음 주 월요일 강남역에서 거래처 담당자 만나기 -> 일정, 날짜 정확, 장소: 강남역, 내용: 거래처 담당자 만나기',
    () {
      final manager = managerAt(DateTime(2026, 7, 29));
      manager.handleUserText('다음 주 월요일 강남역에서 거래처 담당자 만나기');

      expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
      expect(manager.currentDraft?.date, '2026-08-03');
      expect(manager.currentDraft?.location, '강남역');
      expect(manager.currentDraft?.title, '거래처 담당자 만나기');
    },
  );

  test('5. 매주 야구 연습하기 -> 하루 목표, 장소 없음, 내용에 야구 유지', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('매주 야구 연습하기');

    expect(manager.currentDraft?.category, DraftCommandCategory.dailyGoal);
    expect(manager.currentDraft?.location, isNull);
    expect(manager.currentDraft?.title, contains('야구'));
  });

  test('6. 오늘 친구와 즐거웠다 -> 다이어리 유지, 장소 없음', () {
    final manager = managerAt(DateTime(2026, 7, 29));
    manager.handleUserText('오늘 친구와 즐거웠다');

    expect(manager.currentDraft?.category, DraftCommandCategory.diary);
    expect(manager.currentDraft?.location, isNull);
  });
}
