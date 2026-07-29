// GoalCoreRepository/DiaryCoreRepository가 ASON-Core와 같은 저장 키·JSON 구조로
// 정확히 저장하는지 검증합니다. 이전까지 이 두 저장소를 참조하는 테스트가
// 전혀 없었던 공백을 메웁니다.

import 'dart:convert';

import 'package:ason_voice_app/features/core_sync/models/home_goal_entry.dart';
import 'package:ason_voice_app/features/core_sync/services/diary_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/goal_core_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GoalCoreRepository', () {
    test('todayGoals 키에 HomeGoalEntry JSON 배열로 저장된다', () async {
      final repo = GoalCoreRepository();
      await repo.upsert(
        const HomeGoalEntry(id: 'g1', title: '스트레칭', isDone: false),
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('todayGoals');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded.single, {'id': 'g1', 'title': '스트레칭', 'isDone': false});
    });

    test('같은 id로 다시 upsert하면 새로 추가되지 않고 덮어쓴다', () async {
      final repo = GoalCoreRepository();
      await repo.upsert(
        const HomeGoalEntry(id: 'g1', title: '스트레칭', isDone: false),
      );
      await repo.upsert(
        const HomeGoalEntry(id: 'g1', title: '스트레칭', isDone: true),
      );

      final saved = await repo.loadAll();
      expect(saved, hasLength(1));
      expect(saved.single.isDone, isTrue);
    });

    test('다른 id를 upsert하면 기존 목표 옆에 그대로 추가된다', () async {
      final repo = GoalCoreRepository();
      await repo.upsert(
        const HomeGoalEntry(id: 'g1', title: '스트레칭', isDone: false),
      );
      await repo.upsert(
        const HomeGoalEntry(id: 'g2', title: '물 마시기', isDone: false),
      );

      final saved = await repo.loadAll();
      expect(saved, hasLength(2));
      expect(saved.map((e) => e.title), containsAll(['스트레칭', '물 마시기']));
    });
  });

  group('DiaryCoreRepository', () {
    test('diaryEntries 키에 날짜(yyyy-MM-dd)별 문자열 Map으로 저장된다', () async {
      final repo = DiaryCoreRepository();
      final date = DateTime(2026, 7, 29);
      await repo.append(date, '오늘 가족과 여행해서 즐거웠다');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('diaryEntries');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['2026-07-29'], '오늘 가족과 여행해서 즐거웠다');
    });

    test('같은 날짜에 이미 기록이 있으면 덮어쓰지 않고 줄바꿈으로 이어붙인다(기존 설계 유지)', () async {
      final repo = DiaryCoreRepository();
      final date = DateTime(2026, 7, 29);
      await repo.append(date, '첫 번째 기록');
      await repo.append(date, '두 번째 기록');

      final note = await repo.loadForDate(date);
      expect(note, '첫 번째 기록\n두 번째 기록');
    });

    test('다른 날짜의 기록은 서로 영향을 주지 않는다', () async {
      final repo = DiaryCoreRepository();
      await repo.append(DateTime(2026, 7, 29), 'A');
      await repo.append(DateTime(2026, 7, 30), 'B');

      expect(await repo.loadForDate(DateTime(2026, 7, 29)), 'A');
      expect(await repo.loadForDate(DateTime(2026, 7, 30)), 'B');
    });
  });
}
