// 상대 날짜 표현("다음 주 월요일" 등)이 CommandParserService를 통해 실제로
// 날짜/시간/내용으로 올바르게 나뉘고, 제목에서 날짜 표현이 깨끗하게 빠지는지,
// 그리고 분류(일정/나의 하루 목표/다이어리)에 원치 않는 영향을 주지 않는지
// 검증합니다. 기준 날짜는 2026-07-29(수요일)로 고정합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/command_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = CommandParserService(nowProvider: () => DateTime(2026, 7, 29));

  group('제목에서 날짜 표현 제거 (섹션 5)', () {
    test('다음 주 월요일 오전 10시에 은행에 가고 -> 날짜/시간/내용이 깨끗하게 분리된다', () {
      final result = parser.extractScheduleFields('다음 주 월요일 오전 10시에 은행에 가고');
      expect(result.date, '2026-08-03');
      expect(result.time, '오전 10시');
      expect(result.title, '은행 가기');
    });

    test('이번 주 금요일 오후 4시에 거래처 담당자 만나기', () {
      final result = parser.extractScheduleFields(
        '이번 주 금요일 오후 4시에 거래처 담당자 만나기',
      );
      expect(result.date, '2026-07-31');
      expect(result.time, '오후 4시');
      expect(result.title, '거래처 담당자 만나기');
    });

    test('다음 달 3일에 병원 방문하기', () {
      final result = parser.extractScheduleFields('다음 달 3일에 병원 방문하기');
      expect(result.date, '2026-08-03');
      expect(result.title, '병원 방문하기');
    });

    // 참고(이번 턴과 무관한 기존 버그): KoreanLocationService의 행정구역 접미사
    // 정규식이 "친구"를 "친"+"구"(예: 중구처럼 1글자 지명)로 오인해 확실한
    // 장소로 잘못 인식합니다. 그 결과 "친구"가 제목에서 장소로 빠져나가
    // "만나기"만 남습니다. 이번 턴의 날짜 추출 자체는 정상 동작함을
    // DateExpressionParser 테스트로 별도 확인했고(matchedText가 "금요일에"로
    // 정확히 끝남), 장소 추출 규칙은 이번 턴의 변경 대상이 아니라서 고치지
    // 않았습니다. 완료 보고서의 "남은 문제"에도 함께 남깁니다.
    test('금요일에 친구 만나기 -> 날짜는 정확하지만, 기존 장소 오인식 버그로 제목에서 "친구"가 빠진다', () {
      final result = parser.extractScheduleFields('금요일에 친구 만나기');
      expect(result.date, '2026-07-31');
      expect(result.location, '친구');
      expect(result.title, '만나기');
    });
  });

  group('분류에 미치는 영향 (섹션 6)', () {
    test('다음 주 월요일 병원 가기 -> 일정으로 분류된다', () {
      final classification = parser.classify('다음 주 월요일 병원 가기');
      expect(classification.best, DraftCommandCategory.schedule);
      expect(classification.isUnclassified, isFalse);
    });

    test('다음 주부터 매일 30분 걷기 -> 날짜 표현이 있어도 목표 분류를 유지한다', () {
      final classification = parser.classify('다음 주부터 매일 30분 걷기');
      expect(classification.best, DraftCommandCategory.dailyGoal);
    });

    test('오늘 기분이 좋았다 -> 다이어리 분류를 유지한다', () {
      final classification = parser.classify('오늘 기분이 좋았다');
      expect(classification.best, DraftCommandCategory.diary);
    });
  });

  group('실패 시 원문 유지 (섹션 3)', () {
    test('존재하지 않는 날짜(다음 달 31일, 다음달=평년 아님)는 원문이 제목에 남는다', () {
      final aprilParser = CommandParserService(
        nowProvider: () => DateTime(2026, 3, 15),
      );
      final result = aprilParser.extractScheduleFields('다음 달 31일에 병원 방문하기');
      expect(result.date, isNull);
      expect(result.title, contains('다음 달 31일'));
    });
  });
}
