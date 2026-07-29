// FieldNormalizer의 필드별 정규화 규칙을 확인합니다.

import 'package:ason_voice_app/features/core_sync/services/field_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('digitsOnly', () {
    test('숫자만 필요한 필드는 문자/구분 기호를 제거하고 숫자만 남긴다', () {
      expect(FieldNormalizer.digitsOnly('12df34tsd56'), '123456');
    });

    test('숫자가 없으면 빈 문자열이다', () {
      expect(FieldNormalizer.digitsOnly('abc'), '');
    });
  });

  group('normalizeTime', () {
    test('한글 시간 표현을 HH:mm 24시간 형식으로 정규화한다', () {
      expect(FieldNormalizer.normalizeTime('오후 3시'), '15:00');
      expect(FieldNormalizer.normalizeTime('오전 10시 30분'), '10:30');
      expect(FieldNormalizer.normalizeTime('오후 12시'), '12:00');
      expect(FieldNormalizer.normalizeTime('오전 12시'), '00:00');
    });

    test('알 수 없는 형식이거나 null이면 시간 없음(--:--)이다', () {
      expect(FieldNormalizer.normalizeTime(null), '--:--');
      expect(FieldNormalizer.normalizeTime('알 수 없음'), '--:--');
    });
  });

  group('resolveDate', () {
    test('상대적인 한글 날짜 표현을 실제 날짜로 변환한다', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(FieldNormalizer.resolveDate('오늘'), today);
      expect(
        FieldNormalizer.resolveDate('내일'),
        today.add(const Duration(days: 1)),
      );
      expect(
        FieldNormalizer.resolveDate('모레'),
        today.add(const Duration(days: 2)),
      );
      expect(
        FieldNormalizer.resolveDate('어제'),
        today.subtract(const Duration(days: 1)),
      );
    });

    test('"8월 15일" 형식을 실제 날짜 모델로 변환한다', () {
      final now = DateTime.now();
      expect(FieldNormalizer.resolveDate('8월 15일'), DateTime(now.year, 8, 15));
    });
  });
}
