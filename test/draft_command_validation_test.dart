// DraftCommand.hasRequiredContent/validationMessage가 카테고리별로 핵심 내용
// (대부분 title)만 검사하고, 날짜/시간/장소/알림/반복은 필수로 요구하지 않는지
// 검증합니다. 이 검증은 질문이나 채팅 메시지를 만들지 않는, 카드에 붙는 정적
// 판정입니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:flutter_test/flutter_test.dart';

DraftCommand _draft({required DraftCommandCategory category, String? title}) {
  return DraftCommand(
    originalText: '원문',
    status: DraftCommandStatus.ready,
    category: category,
    title: title,
  );
}

void main() {
  group('일정', () {
    test('title이 null이면 유효하지 않다', () {
      final draft = _draft(
        category: DraftCommandCategory.schedule,
        title: null,
      );
      expect(draft.hasRequiredContent, isFalse);
      expect(draft.validationMessage, '내용을 입력하거나 수정해 주세요.');
    });

    test('title이 공백뿐이면 유효하지 않다', () {
      final draft = _draft(
        category: DraftCommandCategory.schedule,
        title: '   ',
      );
      expect(draft.hasRequiredContent, isFalse);
    });

    test('title이 "-"이면 유효하지 않다', () {
      final draft = _draft(category: DraftCommandCategory.schedule, title: '-');
      expect(draft.hasRequiredContent, isFalse);
    });

    test('실제 내용이 있으면 날짜/시간/장소가 없어도 유효하다', () {
      final draft = _draft(
        category: DraftCommandCategory.schedule,
        title: '광고미팅',
      );
      expect(draft.hasRequiredContent, isTrue);
      expect(draft.validationMessage, isNull);
    });
  });

  group('나의 하루 목표', () {
    test('title이 null이면 유효하지 않다', () {
      final draft = _draft(
        category: DraftCommandCategory.dailyGoal,
        title: null,
      );
      expect(draft.hasRequiredContent, isFalse);
    });

    test('실제 내용이 있으면 반복이 없어도 유효하다', () {
      final draft = _draft(
        category: DraftCommandCategory.dailyGoal,
        title: '스트레칭',
      );
      expect(draft.hasRequiredContent, isTrue);
    });
  });

  group('다이어리', () {
    test('title이 null이면 유효하지 않다', () {
      final draft = _draft(category: DraftCommandCategory.diary, title: null);
      expect(draft.hasRequiredContent, isFalse);
    });

    test('실제 내용이 있으면 유효하다', () {
      final draft = _draft(
        category: DraftCommandCategory.diary,
        title: '오늘 가족과 여행해서 즐거웠다',
      );
      expect(draft.hasRequiredContent, isTrue);
    });
  });

  group('메모', () {
    test('title이 null이면 유효하지 않다', () {
      final draft = _draft(category: DraftCommandCategory.memo, title: null);
      expect(draft.hasRequiredContent, isFalse);
    });

    test('실제 내용이 있으면 유효하다', () {
      final draft = _draft(
        category: DraftCommandCategory.memo,
        title: '우유와 계란 구매',
      );
      expect(draft.hasRequiredContent, isTrue);
    });
  });

  group('검증 대상이 아닌 내부 하위 호환 카테고리', () {
    test('건강은 title이 없어도 기존 동작대로 유효하다', () {
      final draft = _draft(category: DraftCommandCategory.health, title: null);
      expect(draft.hasRequiredContent, isTrue);
    });
  });
}
