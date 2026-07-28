// ProjectFieldExtractor가 프로젝트 문장에서 활동(생성/수정/삭제)과 진행률을
// 올바르게 뽑아내는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/services/project_field_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('활동 판단', () {
    test('삭제/제거 표현이 있으면 "삭제"다', () {
      expect(ProjectFieldExtractor.detectAction('다크모드 프로젝트 삭제'), '삭제');
      expect(ProjectFieldExtractor.detectAction('그 프로젝트 제거해줘'), '삭제');
    });

    test('수정/변경 표현이나 진행률이 있으면 "수정"이다', () {
      expect(ProjectFieldExtractor.detectAction('다크모드 프로젝트 수정'), '수정');
      expect(ProjectFieldExtractor.detectAction('진행률 60%로 변경'), '수정');
      expect(ProjectFieldExtractor.detectAction('진행률 60%'), '수정');
    });

    test('아무 표현도 없으면 기본값은 "생성"이다', () {
      expect(ProjectFieldExtractor.detectAction('새 프로젝트: 다크모드 지원'), '생성');
    });
  });

  group('진행률 추출', () {
    test('"60%" 형태를 인식한다', () {
      expect(ProjectFieldExtractor.extractProgress('진행률 60%'), '60%');
    });

    test('"60퍼센트"/"60프로"도 인식해 "%"로 정리한다', () {
      expect(ProjectFieldExtractor.extractProgress('진행률 60퍼센트'), '60%');
      expect(ProjectFieldExtractor.extractProgress('60프로 진행됨'), '60%');
    });

    test('진행률 표현이 없으면 null이다', () {
      expect(ProjectFieldExtractor.extractProgress('새 프로젝트: 다크모드 지원'), isNull);
    });
  });

  group('제목 정리', () {
    test('"새 프로젝트 시작:" 같은 안내성 표현을 앞에서 제거한다', () {
      expect(
        ProjectFieldExtractor.cleanTitle('새 프로젝트 시작: ASON 리브랜딩'),
        'ASON 리브랜딩',
      );
      expect(ProjectFieldExtractor.cleanTitle('프로젝트 생성: 다크모드 지원'), '다크모드 지원');
    });

    test('앞에 안내성 표현이 없으면 그대로 둔다', () {
      expect(ProjectFieldExtractor.cleanTitle('다크모드 지원'), '다크모드 지원');
    });
  });
}
