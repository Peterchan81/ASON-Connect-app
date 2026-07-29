// KoreanLocationService가 "친구"/"야구"처럼 한 글자 어간 + 행정구역 접미사로
// 이루어진 흔한 일반 단어를 장소로 오인식하지 않으면서도, "중구"/"서구"
// 처럼 실제로 짧은 행정구역명과 "강남역"/"중구청" 같은 시설 장소는 계속
// 정상적으로 인식하는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/services/korean_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = KoreanLocationService();

  group('A. 일반 단어 오인식 방지', () {
    for (final word in ['친구', '야구', '축구', '농구', '연구', '도구', '가구', '운동', '행동']) {
      test('"$word" -> 장소가 아니다', () {
        final result = service.extractLocation(word);
        expect(result.isConfident, isFalse, reason: '$word를 장소로 오인식했습니다');
        expect(result.isEmpty, isTrue);
      });
    }

    test('조사가 붙어도 일반 단어는 장소로 확정되지 않는다', () {
      expect(service.extractLocation('친구에게').isConfident, isFalse);
      expect(service.extractLocation('야구에서 배운 점').isConfident, isFalse);
      expect(service.extractLocation('운동으로 건강 관리').isConfident, isFalse);
    });
  });

  group('B. 실제 행정구역 유지', () {
    final cases = {
      '중구': '중구',
      '서구': '서구',
      '동구': '동구',
      '강남구': '강남구',
      '유성구': '유성구',
      '종로구': '종로구',
      '대전시': '대전시',
    };

    cases.forEach((input, expected) {
      test('"$input" -> 장소로 인식($expected)', () {
        final result = service.extractLocation(input);
        expect(result.isConfident, isTrue, reason: '$input을 장소로 인식하지 못했습니다');
        expect(result.text, expected);
      });
    });
  });

  group('C. 시설 장소 유지', () {
    test('강남역에서 미팅', () {
      expect(service.extractLocation('강남역에서 미팅').isConfident, isTrue);
    });

    test('서울역에 가기', () {
      expect(service.extractLocation('서울역에 가기').isConfident, isTrue);
    });

    test('중구청 방문', () {
      expect(service.extractLocation('중구청 방문').isConfident, isTrue);
    });

    test('대전시청 방문', () {
      expect(service.extractLocation('대전시청 방문').isConfident, isTrue);
    });
  });

  group('일반 단어 뒤에 실제 지역명이 나오면 그 지역명을 찾아낸다', () {
    test('친구랑 중구에서 만나 -> 중구', () {
      final result = service.extractLocation('친구랑 중구에서 만나');
      expect(result.isConfident, isTrue);
      expect(result.text, '중구');
    });
  });
}
