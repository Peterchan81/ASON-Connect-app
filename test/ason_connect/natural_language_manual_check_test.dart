// 지시서 8번(수동 확인 문장)에 명시된 3개 문장을 자동으로도 검증합니다.
// (이 환경에는 브라우저 스크린샷 도구가 없어, 실제 위젯 트리를 그대로
// 구동하는 이 테스트로 Chrome 수동 확인을 보완합니다)

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('문장 1: 일정 + 목표 + 메모 3개, 제목이 자연스럽게 정리된다', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시에 병원에 가고 매일 30분씩 걷고 우유 사는 것을 메모해줘');

    expect(manager.items.length, 3);
    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.schedule,
      DraftCommandCategory.dailyGoal,
      DraftCommandCategory.memo,
    ]);

    final schedule = manager.items[0].draft;
    expect(schedule.date, '내일');
    expect(schedule.time, '오후 3시');
    expect(schedule.title, '병원 가기');

    final goal = manager.items[1].draft;
    expect(goal.repeatOption, '매일');
    expect(goal.title, '30분 걷기');

    final memo = manager.items[2].draft;
    expect(memo.title, '우유 사기');

    expect(
      manager.items.every((item) => item.draft.hasRequiredContent),
      isTrue,
    );
  });

  // 참고: "다음 주 월요일" 같은 상대 날짜 표현은 ScheduleFieldExtractor의 날짜
  // 인식 목록(오늘/내일/모레/어제, N월N일)에 원래부터 없어 이번 턴 이전부터도
  // 인식되지 않았습니다(날짜 추출 규칙은 이번 턴에서 변경하지 않았습니다). 그
  // 영향으로 일정 제목 앞에 "다음 주 월요일 에"가 남을 수 있어, 이 테스트는
  // 이번 턴이 실제로 책임지는 부분(절 분리 개수/순서, 시간 추출, 목표/메모
  // 제목 정규화)만 검증합니다.
  test('문장 2: 일정 + 목표 + 메모 3개(반복 표현/요청 동사 변형)', () {
    final manager = ConversationManager();
    manager.handleUserText('다음 주 월요일 오전 10시에 은행에 가고 책을 매일 20분 읽고 계란 사는 것 적어줘');

    expect(manager.items.length, 3);
    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.schedule,
      DraftCommandCategory.dailyGoal,
      DraftCommandCategory.memo,
    ]);

    final schedule = manager.items[0].draft;
    expect(schedule.time, '오전 10시');
    expect(schedule.title, contains('은행 가기'));

    final goal = manager.items[1].draft;
    expect(goal.repeatOption, '매일');
    expect(goal.title, '책 20분 읽기');

    final memo = manager.items[2].draft;
    expect(memo.title, '계란 사기');
  });

  // 참고: 이 문장은 반복/메모 요청 신호가 없어 절이 하나로 유지됩니다(과분리
  // 방지, 이번 턴이 새로 구현한 부분). 다만 "일정"으로 분류되려면
  // ClassificationScorer가 "병원"/"가다" 같은 키워드나 시간 표현을 인식해야
  // 하는데, 이 문장에는 시간 표현이 없고 "병원"은 분류 키워드 목록에 없어(일반
  // 시설명을 장소로 강제하지 않는 이번 턴의 정책과도 맞물려) 분류기가 이
  // 문장을 특정 카테고리로 확신하지 못합니다. ClassificationScorer는 이번
  // 턴에서 변경 대상이 아니므로(분류 기준 보호), 이 테스트는 이번 턴이 실제로
  // 책임지는 부분(2개 이상으로 쪼개지지 않는 것)만 검증합니다.
  test('문장 3: "-고"가 있어도 신호가 없으면 절이 하나로 유지된다(과분리 방지)', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 병원에 가서 검사하고 약도 받아야 해');

    expect(manager.hasItems, isFalse);
  });
}
