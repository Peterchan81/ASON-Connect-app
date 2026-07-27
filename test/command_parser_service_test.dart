// CommandParserService(및 내부에 위임된 ClassificationScorer/ScheduleFieldExtractor/
// HealthFieldExtractor/FieldCorrectionParser)가 문장에서 날짜·시간·장소·건강 수치를
// 올바르게 뽑아내고, 수정 대화의 알림/반복 의사표현을 올바르게 정규화하는지 검증합니다.
// Sprint 11에서 command_parser_service.dart를 역할별로 분리하면서, 그동안 위젯
// 통합 테스트로만 간접 검증되던 파싱 로직을 직접 확인할 수 있도록 추가했습니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/command_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = CommandParserService();

  group('일정 날짜/시간/내용 추출', () {
    test('오늘/오후 시간/내용을 함께 뽑아낸다', () {
      final result = parser.extractScheduleFields('오늘 오후 3시에 팀 회의');

      expect(result.date, '오늘');
      expect(result.time, '오후 3시');
      expect(result.title, '팀 회의');
    });

    test('월/일 형태의 날짜도 인식한다', () {
      final result = parser.extractScheduleFields('8월 15일 계약서 작성');

      expect(result.date, '8월 15일');
      expect(result.title, '계약서 작성');
    });

    test('"일정 있어"처럼 실질적인 내용이 없으면 title은 null이다', () {
      final result = parser.extractScheduleFields('내일 일정 있어');

      expect(result.date, '내일');
      expect(result.title, isNull);
    });
  });

  group('일정 장소 추출', () {
    test('확실한 지역명은 location에 바로 채워진다', () {
      final result = parser.extractScheduleFields('둔산동에서 미팅');

      expect(result.location, '대전 둔산동');
      expect(result.pendingLocationGuess, isNull);
    });

    test('불확실한 지명은 pendingLocationGuess로만 남고 location은 비워둔다', () {
      final result = parser.extractScheduleFields('둔산에서 미팅');

      expect(result.location, isNull);
      expect(result.pendingLocationGuess, isNotNull);
      expect(result.pendingLocationOriginal, '둔산');
    });
  });

  group('건강 수치 추출', () {
    test('혈압을 인식한다', () {
      final result = parser.extractHealthFields('오늘 혈압이 128에 82야.');

      expect(result.item, '혈압');
      expect(result.value, '128 / 82 mmHg');
    });

    test('체중을 인식한다', () {
      final result = parser.extractHealthFields('체중 68.5kg');

      expect(result.item, '체중');
      expect(result.value, '68.5kg');
    });

    test('혈당을 인식한다', () {
      final result = parser.extractHealthFields('혈당 105');

      expect(result.item, '혈당');
      expect(result.value, '105');
    });

    test('운동 표현을 인식한다', () {
      final result = parser.extractHealthFields('오늘 30분간 걸었어');

      expect(result.item, '운동');
      expect(result.value, contains('걸었'));
    });

    test('수치가 없으면 증상으로 정리한다', () {
      final result = parser.extractHealthFields('머리가 아프다.');

      expect(result.item, '증상');
      expect(result.value, '머리가 아프다');
    });
  });

  group('수정 대화의 알림/반복 파싱', () {
    DraftCommand scheduleDraft() => DraftCommand(
      originalText: '테스트',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
    );

    test('"알림 없어"는 알림을 "없음"으로 정규화한다', () {
      final correction = parser.parseFieldCorrection('알림 없어', const ['alarm']);
      expect(correction, isNotNull);

      final updated = parser.applyFieldCorrection(scheduleDraft(), correction!);
      expect(updated.alarm, '없음');
    });

    test('"알림은 30분 전"은 입력한 값을 그대로 사용한다', () {
      final correction = parser.parseFieldCorrection('알림은 30분 전', const [
        'alarm',
      ]);
      expect(correction, isNotNull);

      final updated = parser.applyFieldCorrection(scheduleDraft(), correction!);
      expect(updated.alarm, '30분 전');
    });

    test('"반복은 매주 월요일"은 repeatOption에 반영된다', () {
      final correction = parser.parseFieldCorrection('반복은 매주 월요일', const [
        'repeat',
      ]);
      expect(correction, isNotNull);

      final updated = parser.applyFieldCorrection(scheduleDraft(), correction!);
      expect(updated.repeatOption, '매주 월요일');
    });

    test('"반복 없음"은 repeatOption을 "없음"으로 정규화한다', () {
      final correction = parser.parseFieldCorrection('반복 없음', const ['repeat']);
      expect(correction, isNotNull);

      final updated = parser.applyFieldCorrection(scheduleDraft(), correction!);
      expect(updated.repeatOption, '없음');
    });
  });
}
