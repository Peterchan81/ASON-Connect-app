// ASON-Core와 같은 형태로 저장/복원되는지 각 모델의 JSON 왕복을 검증합니다.

import 'package:ason_voice_app/features/core_sync/models/health_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/home_schedule_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/memo_model.dart';
import 'package:ason_voice_app/features/core_sync/models/project_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeScheduleEntry는 JSON으로 저장했다가 다시 읽어도 같은 값을 유지한다', () {
    final entry = HomeScheduleEntry(
      id: 'voice_1',
      date: DateTime(2026, 7, 29),
      time: '15:00',
      title: '병원 예약',
      isDone: false,
      memo: '대전성모병원',
      alarmEnabled: true,
    );

    final restored = HomeScheduleEntry.fromJson(
      entry.toJson(),
      date: entry.date,
    );

    expect(restored.id, entry.id);
    expect(restored.time, entry.time);
    expect(restored.title, entry.title);
    expect(restored.memo, entry.memo);
    expect(restored.alarmEnabled, entry.alarmEnabled);
    expect(restored.hasTime, isTrue);
    expect(restored.alarmAt, DateTime(2026, 7, 29, 15, 0));
  });

  test('HomeScheduleEntry의 시간이 "--:--"이면 hasTime과 alarmAt이 모두 비활성이다', () {
    final entry = HomeScheduleEntry(
      id: 'voice_2',
      date: DateTime(2026, 7, 29),
      time: '--:--',
      title: '할 일',
      isDone: false,
    );

    expect(entry.hasTime, isFalse);
    expect(entry.alarmAt, isNull);
  });

  test('MemoModel은 JSON으로 저장했다가 다시 읽어도 같은 값을 유지한다', () {
    final memo = MemoModel(
      id: 'voice_3',
      title: 'ASON 음성 앱 다국어 지원',
      content: 'ASON 음성 앱 다국어 지원',
      category: '아이디어',
      tags: const [],
      createdAt: DateTime(2026, 7, 28, 10),
      updatedAt: DateTime(2026, 7, 28, 10),
      isImportant: false,
      alarmEnabled: false,
    );

    final restored = MemoModel.fromJson(memo.toJson());

    expect(restored.id, memo.id);
    expect(restored.title, memo.title);
    expect(restored.content, memo.content);
    expect(restored.category, memo.category);
    expect(restored.createdAt, memo.createdAt);
  });

  test('HealthEntry는 JSON으로 저장했다가 다시 읽어도 같은 값을 유지한다', () {
    final entry = HealthEntry(
      id: 'voice_4',
      item: '혈압',
      value: '128/82',
      date: '오늘',
      createdAt: DateTime(2026, 7, 28, 9),
      updatedAt: DateTime(2026, 7, 28, 9),
    );

    final restored = HealthEntry.fromJson(entry.toJson());

    expect(restored.item, entry.item);
    expect(restored.value, entry.value);
    expect(restored.date, entry.date);
  });

  test('ProjectEntry는 JSON으로 저장했다가 다시 읽어도 같은 값을 유지한다', () {
    final entry = ProjectEntry(
      id: 'voice_5',
      title: 'ASON 리브랜딩',
      action: '수정',
      progress: '60%',
      createdAt: DateTime(2026, 7, 28, 8),
      updatedAt: DateTime(2026, 7, 28, 8),
    );

    final restored = ProjectEntry.fromJson(entry.toJson());

    expect(restored.title, entry.title);
    expect(restored.action, entry.action);
    expect(restored.progress, entry.progress);
  });
}
