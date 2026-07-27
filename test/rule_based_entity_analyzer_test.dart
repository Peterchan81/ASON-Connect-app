// RuleBasedEntityAnalyzer(EntityAnalyzer의 규칙 기반 구현체)가 CommandParserService의
// 카테고리별 추출 결과를 EntityResult로 올바르게 옮겨 담는지, 그리고 수정 대화 파싱을
// 올바르게 위임하는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/adapters/rule_based_entity_analyzer.dart';
import 'package:ason_voice_app/features/ason_connect/services/command_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analyzer = RuleBasedEntityAnalyzer(CommandParserService());

  test('일정 문장에서 날짜/시간/내용을 뽑아낸다', () {
    final result = analyzer.extract(
      DraftCommandCategory.schedule,
      '내일 오후 3시에 팀 회의',
    );

    expect(result.date, '내일');
    expect(result.time, '오후 3시');
    expect(result.title, '팀 회의');
  });

  test('일정 문장에서 확실한 장소를 뽑아낸다', () {
    final result = analyzer.extract(DraftCommandCategory.schedule, '둔산동에서 미팅');

    expect(result.location, '대전 둔산동');
  });

  test('메모 문장의 내용을 자연스럽게 정리한다', () {
    final result = analyzer.extract(DraftCommandCategory.memo, '우유하고 계란 사야 해');

    expect(result.title, '우유와 계란 구매');
  });

  test('건강 문장에서 항목과 수치를 뽑아낸다', () {
    final result = analyzer.extract(
      DraftCommandCategory.health,
      '오늘 혈압이 128에 82야.',
    );

    expect(result.healthItem, '혈압');
    expect(result.title, '128 / 82 mmHg');
  });

  test('수정 대화에서 항목과 새 값을 해석한다', () {
    final correction = analyzer.parseCorrection('시간을 오후 4시로 바꿔줘', const [
      'time',
    ]);

    expect(correction, isNotNull);
    expect(correction?.field, 'time');
    expect(correction?.newValue, '오후 4시');
  });
}
