// 프로젝트 저장소입니다. ASON-Core에는 아직 대응 화면이 없어(PlaceholderScreen),
// ASON Voice가 기준 저장 형태를 먼저 만들어 둡니다.

import '../models/project_entry.dart';
import 'core_data_repository.dart';
import 'json_list_repository.dart';

class ProjectCoreRepository implements CoreDataRepository<ProjectEntry> {
  ProjectCoreRepository()
    : _repo = JsonListRepository<ProjectEntry>(
        storageKey: 'projectStoreV1',
        toJson: (item) => item.toJson(),
        fromJson: ProjectEntry.fromJson,
        idOf: (item) => item.id,
      );

  final JsonListRepository<ProjectEntry> _repo;

  @override
  Future<List<ProjectEntry>> loadAll() => _repo.loadAll();

  @override
  Future<void> upsert(ProjectEntry item) => _repo.upsert(item);

  @override
  Future<void> delete(String id) => _repo.delete(id);
}
