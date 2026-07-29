// 시간 표현(예: "3시", "다음 주 월요일")이 없는 일회성 행동 문장도 문맥에
// 따라 일정으로 분류되는지 검증합니다. UntimedScheduleClassifier가 반복
// 표현(목표)·과거형 감정(다이어리)·희망/구상 표현(메모)이 있는 문장은
// 여전히 그 우선순위를 지키는지도 함께 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/classification_scorer.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:ason_voice_app/features/ason_connect/services/untimed_schedule_classifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final scorer = ClassificationScorer();

  group('시간 없는 일회성 행동 -> 일정', () {
    const sentences = [
      '병원 가야 해',
      '세차 맡기기',
      '주민센터 방문',
      '은행에 서류 제출',
      '어머니께 전화하기',
      '택배 보내기',
      '자동차 검사받기',
      '내일 사용할 자료 출력하기',
    ];

    for (final sentence in sentences) {
      test('$sentence -> 일정', () {
        final result = scorer.classify(sentence);
        expect(result.best, DraftCommandCategory.schedule);
        expect(result.isUnclassified, isFalse);
        expect(result.isAmbiguous, isFalse);
      });
    }
  });

  group('장소가 포함된 시간 없는 행동 -> 일정', () {
    test('주민센터 방문', () {
      final result = scorer.classify('주민센터 방문');
      expect(result.best, DraftCommandCategory.schedule);
    });

    test('강남역에서 서류 제출', () {
      final result = scorer.classify('강남역에서 서류 제출');
      expect(result.best, DraftCommandCategory.schedule);
      expect(result.isAmbiguous, isFalse);
    });
  });

  group('반복 행동 -> 나의 하루 목표(일정으로 잘못 분류되지 않음)', () {
    test('운동을 꾸준히 하자', () {
      final result = scorer.classify('운동을 꾸준히 하자');
      expect(result.best, DraftCommandCategory.dailyGoal);
    });

    test('매일 물 많이 마시기', () {
      final result = scorer.classify('매일 물 많이 마시기');
      expect(result.best, DraftCommandCategory.dailyGoal);
    });

    test('매주 야구 연습하기', () {
      final result = scorer.classify('매주 야구 연습하기');
      expect(result.best, DraftCommandCategory.dailyGoal);
    });

    // "세차 맡기기"는 단독으로는 일정이지만, 반복 표현이 붙으면 목표가
    // 우선입니다.
    test('매일 세차 맡기기', () {
      final result = scorer.classify('매일 세차 맡기기');
      expect(result.best, DraftCommandCategory.dailyGoal);
    });
  });

  group('과거 감정과 경험 -> 다이어리(일정으로 잘못 분류되지 않음)', () {
    test('오늘 기분이 좋았다', () {
      final result = scorer.classify('오늘 기분이 좋았다');
      expect(result.best, DraftCommandCategory.diary);
    });

    test('오늘 친구와 즐거웠다', () {
      final result = scorer.classify('오늘 친구와 즐거웠다');
      expect(result.best, DraftCommandCategory.diary);
    });
  });

  group('아이디어와 희망 -> 일정으로 잘못 분류되지 않음', () {
    const sentences = [
      '좋은 사업 아이디어',
      '자동차 검사 방법 알아보기',
      '언젠가 제주도에서 살아보고 싶다',
      '언젠가 은행에 서류 제출하고 싶다',
      '전화하고 싶다',
      '검사받는 방법 알아보기',
    ];

    for (final sentence in sentences) {
      test('$sentence -> 일정이 아님', () {
        final result = scorer.classify(sentence);
        final wronglySchedule =
            result.best == DraftCommandCategory.schedule &&
            !result.isUnclassified;
        expect(wronglySchedule, isFalse);
      });
    }
  });

  group('UntimedScheduleClassifier.scoreBonus (단위 테스트)', () {
    const classifier = UntimedScheduleClassifier();

    test('용무 표현이 있으면 보너스를 준다', () {
      expect(classifier.scoreBonus('병원 가야 해'), greaterThan(0));
      expect(classifier.scoreBonus('은행에 서류 제출'), greaterThan(0));
      expect(classifier.scoreBonus('어머니께 전화하기'), greaterThan(0));
      expect(classifier.scoreBonus('택배 보내기'), greaterThan(0));
    });

    test('반복 표현이 있으면 보너스가 0이다', () {
      expect(classifier.scoreBonus('매일 세차 맡기기'), 0);
      expect(classifier.scoreBonus('매주 전화하기'), 0);
      expect(classifier.scoreBonus('꾸준히 병원 가야 해'), 0);
    });

    test('과거형 감정 표현이 있으면 보너스가 0이다', () {
      expect(classifier.scoreBonus('오늘 전화하기 힘들었다'), 0);
    });

    test('희망/구상/정보 탐색 표현이 있으면 보너스가 0이다', () {
      expect(classifier.scoreBonus('전화하고 싶다'), 0);
      expect(classifier.scoreBonus('언젠가 은행에 서류 제출하고 싶다'), 0);
      expect(classifier.scoreBonus('검사받는 방법 알아보기'), 0);
      expect(classifier.scoreBonus('사업 아이디어로 방문 판매를 고민 중이다'), 0);
    });

    test('용무 표현도 날짜 표현도 없으면 보너스가 0이다', () {
      expect(classifier.scoreBonus('오늘 기분이 좋았다'), 0);
      expect(classifier.scoreBonus('안녕하세요'), 0);
    });
  });

  group('ConversationManager 수준 통합 확인', () {
    test('병원 가야 해 -> 일정 카드가 생성된다', () {
      final manager = ConversationManager();
      manager.handleUserText('병원 가야 해');

      expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
      expect(manager.currentDraft?.hasRequiredContent, isTrue);
    });

    test('세차 맡기기 -> 일정 카드가 생성된다', () {
      final manager = ConversationManager();
      manager.handleUserText('세차 맡기기');

      expect(manager.currentDraft?.category, DraftCommandCategory.schedule);
    });

    test('회의 아이디어 정리해 두기 -> 메모 카드가 유지된다', () {
      final manager = ConversationManager();
      manager.handleUserText('회의 아이디어 정리해 두기');

      expect(manager.currentDraft?.category, DraftCommandCategory.memo);
    });
  });

  group('기존 상대 날짜/시간 일정 분류 유지', () {
    test('다음 주 월요일 오전 10시에 은행에 가기 -> 일정', () {
      final result = scorer.classify('다음 주 월요일 오전 10시에 은행에 가기');
      expect(result.best, DraftCommandCategory.schedule);
    });

    test('금요일에 친구 만나기 -> 일정', () {
      final result = scorer.classify('금요일에 친구 만나기');
      expect(result.best, DraftCommandCategory.schedule);
    });
  });
}
