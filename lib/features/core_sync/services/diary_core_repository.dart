// ASON-Core의 DiaryNoteService와 완전히 동일한 저장 스키마(SharedPreferences 키
// `diaryEntries`, 날짜별 한 줄 기록 Map<yyyy-MM-dd, String>)를 사용합니다.
// 다이어리 화면이 이미 이 저장소를 읽고 쓰므로, ASON Connect도 같은 키/형태로
// 저장해 별도의 다이어리 저장소를 새로 만들지 않습니다.
//
// 같은 날짜에 이미 기록이 있으면 덮어쓰지 않고 줄바꿈으로 이어 붙입니다. 하루에
// 여러 번 말하거나 입력할 수 있기 때문입니다.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DiaryCoreRepository {
  static const String _storageKey = 'diaryEntries';

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

  /// 특정 날짜의 기록을 읽어옵니다. 없으면 null입니다.
  Future<String?> loadForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    return store[dateKey(date)];
  }

  /// 특정 날짜에 한 줄 기록을 추가합니다. 이미 그 날짜에 기록이 있으면 줄바꿈으로
  /// 이어 붙이고, 없으면 새로 만듭니다.
  Future<void> append(DateTime date, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    final key = dateKey(date);
    final existing = store[key];
    store[key] = (existing == null || existing.trim().isEmpty)
        ? note
        : '$existing\n$note';
    await _saveStore(prefs, store);
  }
}
