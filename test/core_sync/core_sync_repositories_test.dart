// 각 저장소가 ASON-Core와 같은 SharedPreferences 구조로 load/upsert/delete를
// 올바르게 수행하는지 검증합니다.

import 'package:ason_voice_app/features/core_sync/models/health_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/home_schedule_entry.dart';
import 'package:ason_voice_app/features/core_sync/models/memo_model.dart';
import 'package:ason_voice_app/features/core_sync/models/project_entry.dart';
import 'package:ason_voice_app/features/core_sync/services/health_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/memo_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/project_core_repository.dart';
import 'package:ason_voice_app/features/core_sync/services/schedule_core_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScheduleCoreRepository', () {
    test('upsert 후 같은 날짜의 일정을 다시 읽어올 수 있다', () async {
      final repo = ScheduleCoreRepository();
      final entry = HomeScheduleEntry(
        id: 'voice_1',
        date: DateTime(2026, 7, 29),
        time: '15:00',
        title: '병원 예약',
        isDone: false,
        alarmEnabled: true,
      );

      await repo.upsert(entry);
      final all = await repo.loadAll();
      final forDate = await repo.loadForDate(DateTime(2026, 7, 29));

      expect(all, hasLength(1));
      expect(forDate, hasLength(1));
      expect(forDate.single.title, '병원 예약');
    });

    test('같은 id로 다시 upsert하면 새로 추가되지 않고 덮어쓴다', () async {
      final repo = ScheduleCoreRepository();
      final date = DateTime(2026, 7, 29);
      await repo.upsert(
        HomeScheduleEntry(
          id: 'voice_1',
          date: date,
          time: '15:00',
          title: '병원 예약',
          isDone: false,
        ),
      );
      await repo.upsert(
        HomeScheduleEntry(
          id: 'voice_1',
          date: date,
          time: '16:00',
          title: '병원 예약(변경)',
          isDone: false,
        ),
      );

      final all = await repo.loadAll();
      expect(all, hasLength(1));
      expect(all.single.time, '16:00');
      expect(all.single.title, '병원 예약(변경)');
    });

    test('delete하면 해당 id의 일정만 사라진다', () async {
      final repo = ScheduleCoreRepository();
      final date = DateTime(2026, 7, 29);
      await repo.upsert(
        HomeScheduleEntry(
          id: 'voice_1',
          date: date,
          time: '15:00',
          title: '병원 예약',
          isDone: false,
        ),
      );
      await repo.delete('voice_1');

      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('MemoCoreRepository', () {
    test('upsert/loadAll/delete가 올바르게 동작한다', () async {
      final repo = MemoCoreRepository();
      final memo = MemoModel(
        id: 'voice_2',
        title: '아이디어 메모',
        content: '아이디어 메모',
        category: '아이디어',
        tags: const [],
        createdAt: DateTime(2026, 7, 28),
        updatedAt: DateTime(2026, 7, 28),
        isImportant: false,
        alarmEnabled: false,
      );

      await repo.upsert(memo);
      expect(await repo.loadAll(), hasLength(1));

      await repo.delete('voice_2');
      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('HealthCoreRepository', () {
    test('upsert/loadAll/delete가 올바르게 동작한다', () async {
      final repo = HealthCoreRepository();
      final entry = HealthEntry(
        id: 'voice_3',
        item: '혈압',
        value: '128/82',
        createdAt: DateTime(2026, 7, 28),
        updatedAt: DateTime(2026, 7, 28),
      );

      await repo.upsert(entry);
      expect(await repo.loadAll(), hasLength(1));

      await repo.delete('voice_3');
      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('ProjectCoreRepository', () {
    test('upsert/loadAll/delete가 올바르게 동작한다', () async {
      final repo = ProjectCoreRepository();
      final entry = ProjectEntry(
        id: 'voice_4',
        title: 'ASON 리브랜딩',
        action: '생성',
        createdAt: DateTime(2026, 7, 28),
        updatedAt: DateTime(2026, 7, 28),
      );

      await repo.upsert(entry);
      expect(await repo.loadAll(), hasLength(1));

      await repo.delete('voice_4');
      expect(await repo.loadAll(), isEmpty);
    });
  });
}
