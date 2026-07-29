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
