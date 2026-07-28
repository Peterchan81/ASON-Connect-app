// ASON-Core의 ScheduleService와 완전히 동일한 저장 스키마(SharedPreferences 키
// `scheduleByDate`, 날짜별 JSON 맵)를 사용합니다. 홈 화면의 "오늘 일정" 카드와
// 다이어리 화면이 이미 이 저장소를 공유해서 읽고 쓰므로, ASON Voice도 같은
// 키/형태로 저장해 별도의 일정 저장소를 새로 만들지 않습니다.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_schedule_entry.dart';
import 'core_data_repository.dart';

class ScheduleCoreRepository implements CoreDataRepository<HomeScheduleEntry> {
  static const String _storageKey = 'scheduleByDate';

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<Map<String, List<HomeScheduleEntry>>> _loadStore(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final date = _parseDateKey(key);
      return MapEntry(
        key,
        (value as List<dynamic>)
            .map(
              (e) => HomeScheduleEntry.fromJson(
                e as Map<String, dynamic>,
                date: date,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> _saveStore(
    SharedPreferences prefs,
    Map<String, List<HomeScheduleEntry>> store,
  ) async {
    final encoded = jsonEncode(
      store.map(
        (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
      ),
    );
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<List<HomeScheduleEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    return store.values.expand((items) => items).toList();
  }

  /// 특정 날짜의 일정만 읽어옵니다. (ASON-Core의 다이어리/홈 화면과 같은 조회 단위)
  Future<List<HomeScheduleEntry>> loadForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    return store[_dateKey(date)] ?? const [];
  }

  @override
  Future<void> upsert(HomeScheduleEntry item) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    final key = _dateKey(item.date);
    final list = [...(store[key] ?? const <HomeScheduleEntry>[])];
    final index = list.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
    store[key] = list;
    await _saveStore(prefs, store);
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _loadStore(prefs);
    for (final key in store.keys.toList()) {
      store[key] = store[key]!.where((e) => e.id != id).toList();
    }
    await _saveStore(prefs, store);
  }
}
