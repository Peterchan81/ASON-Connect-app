// TitleNormalizer가 "-고" 연결형을 "-기" 종결형으로 자연스럽게 바꾸고, 메모
// 요청 동사를 정리하는지 검증합니다. 패턴이 맞지 않으면 원문을 그대로
// 돌려주는지(정규화 실패 시 원문 유지)도 함께 확인합니다.

import 'package:ason_voice_app/features/ason_connect/services/title_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeActionTitle — 일정', () {
    test('병원에 가고 -> 병원 가기', () {
      expect(TitleNormalizer.normalizeActionTitle('병원에 가고'), '병원 가기');
    });

    test('은행에 가고 -> 은행 가기', () {
      expect(TitleNormalizer.normalizeActionTitle('은행에 가고'), '은행 가기');
    });

    test('거래처 담당자를 만나고 -> 거래처 담당자 만나기', () {
      expect(
        TitleNormalizer.normalizeActionTitle('거래처 담당자를 만나고'),
        '거래처 담당자 만나기',
      );
    });

    test('회의하고 -> 회의하기', () {
      expect(TitleNormalizer.normalizeActionTitle('회의하고'), '회의하기');
    });

    test('방문하고 -> 방문하기', () {
      expect(TitleNormalizer.normalizeActionTitle('방문하고'), '방문하기');
    });
  });

  group('normalizeActionTitle — 나의 하루 목표', () {
    test('30분씩 걷고 -> 30분 걷기', () {
      expect(TitleNormalizer.normalizeActionTitle('30분씩 걷고'), '30분 걷기');
    });

    test('책을 20분 읽고 -> 책 20분 읽기', () {
      expect(TitleNormalizer.normalizeActionTitle('책을 20분 읽고'), '책 20분 읽기');
    });

    test('물 한 잔 마시고 -> 물 한 잔 마시기', () {
      expect(TitleNormalizer.normalizeActionTitle('물 한 잔 마시고'), '물 한 잔 마시기');
    });

    test('스트레칭하고 -> 스트레칭하기', () {
      expect(TitleNormalizer.normalizeActionTitle('스트레칭하고'), '스트레칭하기');
    });
  });

  group('normalizeActionTitle — 이미 "-기"로 끝난 경우도 조사를 정리한다', () {
    test('은행에 가기 -> 은행 가기', () {
      expect(TitleNormalizer.normalizeActionTitle('은행에 가기'), '은행 가기');
    });

    test('책을 20분 읽기 -> 책 20분 읽기', () {
      expect(TitleNormalizer.normalizeActionTitle('책을 20분 읽기'), '책 20분 읽기');
    });

    test('조사가 없으면 그대로 둔다', () {
      expect(
        TitleNormalizer.normalizeActionTitle('거래처 담당자 만나기'),
        '거래처 담당자 만나기',
      );
    });
  });

  group('normalizeActionTitle — 과도한 변환 방지', () {
    test('"-고"로 끝나지 않으면 원문을 그대로 돌려준다', () {
      expect(
        TitleNormalizer.normalizeActionTitle('검사하고 약도 받아야 해'),
        '검사하고 약도 받아야 해',
      );
      expect(TitleNormalizer.normalizeActionTitle('친구하고 영화 보기'), '친구하고 영화 보기');
      expect(TitleNormalizer.normalizeActionTitle('공부하고 싶다'), '공부하고 싶다');
      expect(TitleNormalizer.normalizeActionTitle('걷고 있는 중이다'), '걷고 있는 중이다');
    });

    test('사람 이름/고유명사에 붙은 조사(에게 등)는 건드리지 않는다', () {
      expect(
        TitleNormalizer.normalizeActionTitle('김 부장에게 전화하고'),
        '김 부장에게 전화하기',
      );
    });
  });

  group('normalizeMemoRequest', () {
    test('우유 사는 것을 메모해줘 -> 우유 사기', () {
      expect(TitleNormalizer.normalizeMemoRequest('우유 사는 것을 메모해줘'), '우유 사기');
    });

    test('계란 사야 하는 것 적어줘 -> 계란 사기', () {
      expect(TitleNormalizer.normalizeMemoRequest('계란 사야 하는 것 적어줘'), '계란 사기');
    });

    test('김 부장에게 전화하는 것 기억해줘 -> 김 부장에게 전화하기', () {
      expect(
        TitleNormalizer.normalizeMemoRequest('김 부장에게 전화하는 것 기억해줘'),
        '김 부장에게 전화하기',
      );
    });

    test('아이디어 기록해줘 -> 아이디어', () {
      expect(TitleNormalizer.normalizeMemoRequest('아이디어 기록해줘'), '아이디어');
    });

    test('요청 동사가 없으면 원문을 그대로 돌려준다', () {
      expect(TitleNormalizer.normalizeMemoRequest('우유와 계란 구매'), '우유와 계란 구매');
    });

    test('"메모해 줘"처럼 띄어 쓴 요청 동사도 인식한다', () {
      expect(TitleNormalizer.normalizeMemoRequest('우유 사는 것을 메모해 줘'), '우유 사기');
    });
  });
}
