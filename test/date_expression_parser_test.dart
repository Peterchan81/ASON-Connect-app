// DateExpressionParser가 "다음 주 월요일"/"이번 달 3일"/"금요일" 같은 상대
// 날짜 표현을 실제 날짜로 정확히 계산하는지 검증합니다. 기준 날짜는 항상
// 고정된 nowProvider로 주입해, 실행 시점에 관계없이 결과가 같습니다.

import 'package:ason_voice_app/features/ason_connect/services/date_expression_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-07-29는 수요일입니다.
  DateExpressionParser parserAt(DateTime fixedNow) =>
      DateExpressionParser(nowProvider: () => fixedNow);

  group('주 단위 (기준일 2026-07-29 수요일)', () {
    final parser = parserAt(DateTime(2026, 7, 29));

    test('이번 주 월요일 -> 2026-07-27', () {
      expect(parser.extract('이번 주 월요일')?.formatted, '2026-07-27');
    });

    test('이번주 금요일 -> 2026-07-31', () {
      expect(parser.extract('이번주 금요일')?.formatted, '2026-07-31');
    });

    test('다음 주 월요일 -> 2026-08-03', () {
      expect(parser.extract('다음 주 월요일')?.formatted, '2026-08-03');
    });

    test('다다음 주 월요일 -> 2026-08-10', () {
      expect(parser.extract('다다음 주 월요일')?.formatted, '2026-08-10');
    });

    test('지난 주 월요일 -> 2026-07-20', () {
      expect(parser.extract('지난 주 월요일')?.formatted, '2026-07-20');
    });
  });

  group('요일 단독 (기준일 2026-07-29 수요일)', () {
    final parser = parserAt(DateTime(2026, 7, 29));

    test('금요일 -> 2026-07-31 (아직 지나지 않은 이번 주 금요일)', () {
      expect(parser.extract('금요일')?.formatted, '2026-07-31');
    });

    test('월요일 -> 2026-08-03 (이미 지난 요일은 다음 주)', () {
      expect(parser.extract('월요일')?.formatted, '2026-08-03');
    });

    test('수요일 -> 2026-07-29 (오늘과 같은 요일이면 오늘)', () {
      expect(parser.extract('수요일')?.formatted, '2026-07-29');
    });
  });

  group('월 단위 (기준일 2026-07-29 수요일)', () {
    final parser = parserAt(DateTime(2026, 7, 29));

    test('이번 달 3일 -> 2026-07-03', () {
      expect(parser.extract('이번 달 3일')?.formatted, '2026-07-03');
    });

    test('다음 달 3일 -> 2026-08-03', () {
      expect(parser.extract('다음 달 3일')?.formatted, '2026-08-03');
    });

    test('다다음 달 3일 -> 2026-09-03', () {
      expect(parser.extract('다다음 달 3일')?.formatted, '2026-09-03');
    });

    test('지난 달 3일 -> 2026-06-03', () {
      expect(parser.extract('지난 달 3일')?.formatted, '2026-06-03');
    });
  });

  group('연도 경계 (기준일 2026-12-29)', () {
    final parser = parserAt(DateTime(2026, 12, 29));

    test('다음 달 3일 -> 2027-01-03', () {
      expect(parser.extract('다음 달 3일')?.formatted, '2027-01-03');
    });

    test('다음 주 월요일 -> 2027-01-04', () {
      expect(parser.extract('다음 주 월요일')?.formatted, '2027-01-04');
    });
  });

  group('윤년 및 유효성', () {
    test('2028년은 윤년이라 다음 달 29일(2월)이 유효하다', () {
      final parser = parserAt(DateTime(2028, 1, 15));
      expect(parser.extract('다음 달 29일')?.formatted, '2028-02-29');
    });

    test('평년 2월에는 30일이 없어 실패로 처리한다(원문 유지)', () {
      final parser = parserAt(DateTime(2026, 1, 15));
      expect(parser.extract('다음 달 30일'), isNull);
    });

    test('4월은 31일이 없어 실패로 처리한다(원문 유지)', () {
      final parser = parserAt(DateTime(2026, 3, 15));
      expect(parser.extract('다음 달 31일'), isNull);
    });
  });

  group('과도한 매칭 방지', () {
    final parser = parserAt(DateTime(2026, 7, 29));

    test('"다음 주부터"처럼 요일이 없으면 매칭하지 않는다', () {
      expect(parser.extract('다음 주부터 매일 30분 걷기'), isNull);
    });

    test('상대 날짜 표현이 전혀 없으면 null을 돌려준다', () {
      expect(parser.extract('우유 사기'), isNull);
    });
  });

  group('기존 절대 날짜 표현과 겹치지 않는다', () {
    final parser = parserAt(DateTime(2026, 7, 29));

    test('"내일"은 이 파서의 대상이 아니다(null)', () {
      expect(parser.extract('내일 병원 가기'), isNull);
    });

    test('"7월 30일"은 이 파서의 대상이 아니다(null)', () {
      expect(parser.extract('7월 30일 병원 가기'), isNull);
    });
  });
}
