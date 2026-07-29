// ASON-Core의 GoalService와 완전히 동일한 저장 스키마(SharedPreferences 키
// `todayGoals`, JSON 배열)를 사용합니다. 홈 화면의 "나의 목표 채우기" 카드가
// 이미 이 저장소를 읽고 쓰므로, ASON Connect도 같은 키/형태로 저장해 별도의
// 목표 저장소를 새로 만들지 않습니다.

import '../models/home_goal_entry.dart';
import 'core_data_repository.dart';
import 'json_list_repository.dart';

class GoalCoreRepository implements CoreDataRepository<HomeGoalEntry> {
  GoalCoreRepository()
    : _repo = JsonListRepository<HomeGoalEntry>(
        storageKey: 'todayGoals',
        toJson: (item) => item.toJson(),
        fromJson: HomeGoalEntry.fromJson,
        idOf: (item) => item.id,
      );

  final JsonListRepository<HomeGoalEntry> _repo;

  @override
  Future<List<HomeGoalEntry>> loadAll() => _repo.loadAll();

  @override
  Future<void> upsert(HomeGoalEntry item) => _repo.upsert(item);

  @override
  Future<void> delete(String id) => _repo.delete(id);
}
