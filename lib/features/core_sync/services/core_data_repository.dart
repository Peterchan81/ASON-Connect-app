// 일정/메모/건강/프로젝트 데이터가 모두 같은 저장 방식을 쓰도록 강제하는
// 공통 인터페이스입니다. Brain Engine의 결과(DraftCommand)는 CoreSyncMapper를
// 거쳐 이 인터페이스의 upsert()로만 저장되고, 다른 저장 경로는 두지 않습니다.
// (중복 저장/중복 모델 금지) 이 인터페이스는 그대로 "지금까지 저장된 데이터를
// 모두 읽어오는" AI용 데이터 접근 창구(loadAll)로도 재사용할 수 있습니다.
abstract class CoreDataRepository<T> {
  /// 저장된 모든 항목을 읽어옵니다. (추후 AI가 컨텍스트로 사용할 데이터 접근 창구)
  Future<List<T>> loadAll();

  /// id가 같은 항목이 있으면 덮어쓰고, 없으면 새로 추가합니다.
  Future<void> upsert(T item);

  /// id로 항목을 지웁니다.
  Future<void> delete(String id);
}
