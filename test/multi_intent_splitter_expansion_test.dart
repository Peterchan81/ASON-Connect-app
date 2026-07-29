// MultiIntentSplitter가 쉼표/마침표 외에 "그리고/그다음/또/하고" 같은 연결어도
// 절 경계로 인식하는지, 하나의 일정 문장을 과도하게 쪼개지 않는지, 연결어가
// 반복돼도 빈 절을 만들지 않는지 검증합니다.

import 'package:ason_voice_app/features/brain/services/multi_intent_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const splitter = MultiIntentSplitter();

  group('연결어 변형', () {
    test('쉼표로 나뉜 문장은 그대로 분리된다', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약, 매일 아침 물 마시기');
      expect(clauses, ['내일 오후 3시 병원 예약', '매일 아침 물 마시기']);
    });

    test('마침표로 나뉜 문장은 그대로 분리된다', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약. 매일 아침 물 마시기.');
      expect(clauses, ['내일 오후 3시 병원 예약', '매일 아침 물 마시기']);
    });

    test('"그리고"로 이어 말해도 분리된다', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약 그리고 매일 아침 물 마시기');
      expect(clauses, ['내일 오후 3시 병원 예약', '매일 아침 물 마시기']);
    });

    test('"또"로 이어 말해도 분리된다', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약 또 매일 아침 물 마시기');
      expect(clauses, ['내일 오후 3시 병원 예약', '매일 아침 물 마시기']);
    });

    test('"그다음"으로 이어 말해도 분리된다', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약 그다음 매일 아침 물 마시기');
      expect(clauses, ['내일 오후 3시 병원 예약', '매일 아침 물 마시기']);
    });

    test('동사에 바로 붙은 "-하고"는 절 경계로 오인하지 않는다(쉼표가 실제 경계)', () {
      final clauses = splitter.splitClauses('내일 오후 3시 병원 예약하고, 매일 아침 물 마시기');
      expect(clauses, ['내일 오후 3시 병원 예약하고', '매일 아침 물 마시기']);
    });
  });

  group('과분리 방지', () {
    test('하나의 일정을 설명하는 문장은 여러 카드로 쪼개지 않는다', () {
      final clauses = splitter.splitClauses('내일 오후 3시에 병원에 가서 검사하고 약도 받아야 해');
      expect(clauses, hasLength(1));
      expect(clauses.single, '내일 오후 3시에 병원에 가서 검사하고 약도 받아야 해');
    });

    test('신호(반복/메모 요청)가 전혀 없으면 "-고"가 있어도 나누지 않는다', () {
      expect(splitter.splitClauses('친구하고 영화 보기'), ['친구하고 영화 보기']);
      expect(splitter.splitClauses('공부하고 싶다'), ['공부하고 싶다']);
    });
  });

  group('메모 요청 표현으로 절 경계 인식', () {
    test('쉼표 없이 이어 말해도 메모 요청 앞의 "-고" 지점에서 나뉜다', () {
      final clauses = splitter.splitClauses('매일 30분씩 걷고 우유 사는 것을 메모해줘');
      expect(clauses, ['매일 30분씩 걷고', '우유 사는 것을 메모해줘']);
    });

    test('기록해줘/적어줘/기억해줘도 같은 방식으로 경계를 인식한다', () {
      expect(splitter.splitClauses('매일 30분씩 걷고 우유 사는 것을 기록해줘'), [
        '매일 30분씩 걷고',
        '우유 사는 것을 기록해줘',
      ]);
      expect(splitter.splitClauses('매일 30분씩 걷고 우유 사는 것을 적어줘'), [
        '매일 30분씩 걷고',
        '우유 사는 것을 적어줘',
      ]);
      expect(splitter.splitClauses('매일 30분씩 걷고 우유 사는 것을 기억해줘'), [
        '매일 30분씩 걷고',
        '우유 사는 것을 기억해줘',
      ]);
    });

    test('일정 + 목표 + 메모 3개 절로 나뉜다(대표 예시)', () {
      final clauses = splitter.splitClauses(
        '내일 오후 3시에 병원에 가고 매일 30분씩 걷고 우유 사는 것을 메모해줘',
      );
      expect(clauses, ['내일 오후 3시에 병원에 가고', '매일 30분씩 걷고', '우유 사는 것을 메모해줘']);
    });

    test('반복 신호 없이 일정 + 메모 두 절만 있어도 나뉜다', () {
      final clauses = splitter.splitClauses(
        '다음 주 월요일 오전 10시에 은행에 가고 책을 매일 20분 읽고 계란 사는 것 적어줘',
      );
      expect(clauses, [
        '다음 주 월요일 오전 10시에 은행에 가고',
        '책을 매일 20분 읽고',
        '계란 사는 것 적어줘',
      ]);
    });

    test('메모 요청 표현만 있고 앞에 다른 절이 없으면 나누지 않는다', () {
      expect(splitter.splitClauses('우유 사는 것을 메모해줘'), ['우유 사는 것을 메모해줘']);
    });
  });

  group('빈 절 방지', () {
    test('쉼표와 연결어가 반복돼도 빈 절이 생기지 않는다', () {
      final clauses = splitter.splitClauses(
        '내일 오후 3시 병원 가고, 그리고, 우유 사는 것 메모해줘',
      );
      expect(clauses, hasLength(2));
      expect(clauses, isNot(contains('그리고')));
      expect(clauses.every((c) => c.trim().isNotEmpty), isTrue);
    });

    test('연결어만 반복되는 입력은 절이 전부 걸러진다', () {
      final clauses = splitter.splitClauses('그리고, 또, 그다음');
      expect(clauses, isEmpty);
    });
  });
}
