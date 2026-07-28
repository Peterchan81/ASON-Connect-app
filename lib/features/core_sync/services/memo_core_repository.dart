// 메모 데이터의 저장소입니다. ASON-Core는 아직 메모를 메모리에서만 관리하지만
// (lib/mock/memo_mock_data.dart), 모델 형태는 동일하게 맞춰 두었으므로 ASON-Core가
// 실제 저장소를 붙일 때 이 파일의 저장 키/형태를 그대로 채택할 수 있습니다.

import '../models/memo_model.dart';
import 'core_data_repository.dart';
import 'json_list_repository.dart';

class MemoCoreRepository implements CoreDataRepository<MemoModel> {
  MemoCoreRepository()
    : _repo = JsonListRepository<MemoModel>(
        storageKey: 'memoStoreV1',
        toJson: (item) => item.toJson(),
        fromJson: MemoModel.fromJson,
        idOf: (item) => item.id,
      );

  final JsonListRepository<MemoModel> _repo;

  @override
  Future<List<MemoModel>> loadAll() => _repo.loadAll();

  @override
  Future<void> upsert(MemoModel item) => _repo.upsert(item);

  @override
  Future<void> delete(String id) => _repo.delete(id);
}
