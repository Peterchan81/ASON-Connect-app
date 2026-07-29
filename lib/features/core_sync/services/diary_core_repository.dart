// ASON-Core의 DiaryNoteService와 완전히 동일한 저장 스키마(SharedPreferences 키
// `diaryEntries`, 날짜별 한 줄 기록 Map<yyyy-MM-dd, String>)를 사용합니다.
// 다이어리 화면이 이미 이 저장소를 읽고 쓰므로, ASON Connect도 같은 키/형태로
// 저장해 별도의 다이어리 저장소를 새로 만들지 않습니다. Core는 이 키만 알면
// 되고, 지금까지와 똑같이 "날짜 -> 한 줄 문자열"로 그대로 읽고 씁니다.
//
// 다만 Connect는 같은 항목(같은 id)을 수정 후 다시 동기화하는 일이 흔합니다.
// `diaryEntries`의 값 자체는 이미 여러 줄이 합쳐진 문자열이라 "이 줄이 어느
// id에서 왔는지"를 알 방법이 없어, 그대로는 같은 id를 다시 저장할 때마다
// 줄이 계속 늘어나 버립니다. 이를 막기 위해 Connect 내부에서만 쓰는 색인
// (`diaryEntriesConnectIndex`, 날짜별 [{id, content}] 목록)을 별도로 두고,
// `diaryEntries`의 문자열 값은 항상 이 색인으로부터 다시 만들어(rebuild) 씁니다.
// Core는 이 색인 키를 몰라도 되며, `diaryEntries`를 읽는 기존 방식은 전혀
// 바뀌지 않습니다. 색인이 아직 없는 날짜에 처음 기록할 때는, 그 날짜에 이미
// 있던(= Core가 직접 썼거나 이전 버전의 Connect가 남긴) 문자열을 지우지 않고
// 이름 없는 "기존 기록" 한 줄로 그대로 흡수해 유지합니다.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DiaryCoreRepository {
  static const String _storageKey = 'diaryEntries';
  static const String _indexStorageKey = 'diaryEntriesConnectIndex';

  // 색인이 없던 날짜에 원래 있던 문자열을 흡수해 둘 때 쓰는 예약 id입니다.
  // 실제 동기화 id(`voice_<microsecondsSinceEpoch>`)와 절대 겹치지 않습니다.
  static const String _legacyEntryId = '__legacy__';

  int _appendCounter = 0;

  String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, String>> _loadStore(SharedPreferences prefs) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _saveStore(
    SharedPreferences prefs,
    Map<String, String> store,
  ) async {
    await prefs.setString(_storageKey, jsonEncode(store));
  }

  Future<Map<String, List<Map<String, String>>>> _loadIndex(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_indexStorageKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final list = (value as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).cast<String, String>())
          .toList();
      return MapEntry(key, list);
    });
  }

  Future<void> _saveIndex(
    SharedPreferences prefs,
    Map<String, List<Map<String, String>>> index,
  ) async {
    await prefs.setString(_indexStorageKey, jsonEncode(index));
  }

  /// 특정 날짜의 기록을 읽어옵니다. 없으면 null입니다. (Core와 완전히 같은
  /// 읽기 방식 — 색인 유무와 무관하게 항상 `diaryEntries`에서 직접 읽습니다)
  Future<String?> loadForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    return store[dateKey(date)];
  }

  /// [id]로 다이어리 한 줄을 저장합니다. 같은 id로 다시 저장하면(수정 후 재동기화)
  /// 그 줄의 내용만 바뀌고 새 줄이 추가되지 않습니다. 새 id면 같은 날짜라도
  /// 새 줄로 추가됩니다. 이전에 다른 날짜에 같은 id로 저장한 적이 있으면 그
  /// 날짜에서는 지워지고 새 날짜로 옮겨집니다. 기존에 색인 없이 쌓여 있던
  /// 문자열은 삭제하지 않고 이름 없는 한 줄로 그대로 유지합니다.
  Future<void> upsert(DateTime date, String id, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    final index = await _loadIndex(prefs);
    final targetKey = dateKey(date);

    final affectedKeys = <String>{targetKey};

    // 같은 id가 다른 날짜에 있었다면(수정으로 날짜가 바뀐 경우) 그 날짜에서 제거합니다.
    for (final key in index.keys.toList()) {
      if (key == targetKey) continue;
      final list = index[key];
      if (list == null) continue;
      final before = list.length;
      list.removeWhere((entry) => entry['id'] == id);
      if (list.length != before) affectedKeys.add(key);
    }

    final targetList = index.putIfAbsent(targetKey, () => []);
    if (targetList.isEmpty) {
      // 이 날짜에 색인이 아직 없는데 기존 문자열이 있다면(Core가 직접 썼거나
      // 이전 버전의 Connect가 남긴 기록), 지우지 않고 이름 없는 한 줄로 흡수합니다.
      final legacyText = store[targetKey];
      if (legacyText != null && legacyText.trim().isNotEmpty) {
        targetList.add({'id': _legacyEntryId, 'content': legacyText});
      }
    }

    final existingIndex = targetList.indexWhere((entry) => entry['id'] == id);
    if (existingIndex >= 0) {
      targetList[existingIndex] = {'id': id, 'content': content};
    } else {
      targetList.add({'id': id, 'content': content});
    }

    for (final key in affectedKeys) {
      final list = index[key] ?? const [];
      if (list.isEmpty) {
        store.remove(key);
        index.remove(key);
      } else {
        store[key] = list.map((entry) => entry['content']!).join('\n');
      }
    }

    await _saveStore(prefs, store);
    await _saveIndex(prefs, index);
  }

  /// id 없이 한 줄을 추가합니다. (하위 호환용 — 새 코드는 [upsert]를 사용합니다)
  /// 호출할 때마다 항상 새 줄로 추가되며, 다시 불러도 합쳐지지 않습니다.
  Future<void> append(DateTime date, String note) async {
    _appendCounter += 1;
    final id =
        '__append_${DateTime.now().microsecondsSinceEpoch}_$_appendCounter';
    await upsert(date, id, note);
  }
}
