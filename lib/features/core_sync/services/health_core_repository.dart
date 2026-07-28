// 건강 기록 저장소입니다. ASON-Core에는 아직 대응 화면이 없어(PlaceholderScreen),
// ASON Voice가 기준 저장 형태를 먼저 만들어 둡니다.

import '../models/health_entry.dart';
import 'core_data_repository.dart';
import 'json_list_repository.dart';

class HealthCoreRepository implements CoreDataRepository<HealthEntry> {
  HealthCoreRepository()
    : _repo = JsonListRepository<HealthEntry>(
        storageKey: 'healthStoreV1',
        toJson: (item) => item.toJson(),
        fromJson: HealthEntry.fromJson,
        idOf: (item) => item.id,
      );

  final JsonListRepository<HealthEntry> _repo;

  @override
  Future<List<HealthEntry>> loadAll() => _repo.loadAll();

  @override
  Future<void> upsert(HealthEntry item) => _repo.upsert(item);

  @override
  Future<void> delete(String id) => _repo.delete(id);
}
