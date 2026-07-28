// 메모/건강/프로젝트처럼 "항목 목록 하나를 JSON 배열로 저장"하는 카테고리가
// 공통으로 사용하는 저장 구현입니다. 카테고리마다 새로 파일 입출력 코드를 만들지
// 않도록(중복 저장 로직 금지) 이 클래스 하나로 통일합니다.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'core_data_repository.dart';

class JsonListRepository<T> implements CoreDataRepository<T> {
  JsonListRepository({
    required this.storageKey,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
  });

  final String storageKey;
  final Map<String, dynamic> Function(T item) toJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final String Function(T item) idOf;

  @override
  Future<List<T>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> upsert(T item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await loadAll();
    final index = items.indexWhere((e) => idOf(e) == idOf(item));
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await prefs.setString(storageKey, jsonEncode(items.map(toJson).toList()));
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await loadAll();
    items.removeWhere((e) => idOf(e) == id);
    await prefs.setString(storageKey, jsonEncode(items.map(toJson).toList()));
  }
}
