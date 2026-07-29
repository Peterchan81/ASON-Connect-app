// 한 문장에 3개의 서로 다른 의도가 섞여 있을 때, 입력한 순서 그대로 카드가
// 만들어지는지 검증합니다. 절 하나하나의 분류 자체는 기존 ClassificationScorer
// 기준을 그대로 사용합니다(이번 작업에서 분류 기준은 바꾸지 않습니다).

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('3개 항목 분리: 일정 -> 나의 하루 목표 -> 메모 순서로 카드가 생성된다', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시에 병원 가고, 매일 아침 물 마시기, 회의 아이디어 정리해 두기');

    expect(manager.items.length, 3);
    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.schedule,
      DraftCommandCategory.dailyGoal,
      DraftCommandCategory.memo,
    ]);
  });

  test('순서 변형: 메모 -> 일정 -> 나의 하루 목표', () {
    final manager = ConversationManager();
    manager.handleUserText('회의 아이디어 정리해 두기, 내일 오후 3시 병원 예약, 매일 아침 물 마시기');

    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.memo,
      DraftCommandCategory.schedule,
      DraftCommandCategory.dailyGoal,
    ]);
  });

  test('순서 변형: 다이어리 -> 메모 -> 일정', () {
    final manager = ConversationManager();
    manager.handleUserText('오늘 가족과 여행해서 즐거웠다, 회의 아이디어 정리해 두기, 내일 오후 3시 병원 예약');

    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.diary,
      DraftCommandCategory.memo,
      DraftCommandCategory.schedule,
    ]);
  });

  test('순서 변형: 나의 하루 목표 -> 일정 -> 다이어리', () {
    final manager = ConversationManager();
    manager.handleUserText('매일 아침 물 마시기, 내일 오후 3시 병원 예약, 오늘 가족과 여행해서 즐거웠다');

    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.dailyGoal,
      DraftCommandCategory.schedule,
      DraftCommandCategory.diary,
    ]);
  });

  test('연결어("그리고")로 이어 말해도 순서와 분류가 그대로 유지된다', () {
    final manager = ConversationManager();
    manager.handleUserText('내일 오후 3시 병원 예약 그리고 매일 아침 물 마시기');

    expect(manager.items.map((item) => item.draft.category).toList(), [
      DraftCommandCategory.schedule,
      DraftCommandCategory.dailyGoal,
    ]);
  });
}
