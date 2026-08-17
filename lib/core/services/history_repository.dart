import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_models.dart';
import '../../domain/models/models.dart';
import '../config/app_config.dart';
import 'image_storage_service.dart';

class HistoryRepository {
  HistoryRepository(this._prefs, this._storage);

  final SharedPreferences _prefs;
  final ImageStorageService _storage;
  final _uuid = const Uuid();

  static const _key = 'history_items_v1';

  List<HistoryItem> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<HistoryItem> add({
    required AiOperation operation,
    required String originalPath,
    required String processedPath,
    required bool isPro,
  }) async {
    final items = getAll();
    final item = HistoryItem(
      id: _uuid.v4(),
      operation: operation,
      originalPath: originalPath,
      processedPath: processedPath,
      createdAt: DateTime.now(),
    );
    items.insert(0, item);

    if (!isPro && items.length > AppConfig.freeHistoryLimit) {
      final overflow = items.sublist(AppConfig.freeHistoryLimit);
      items.removeRange(AppConfig.freeHistoryLimit, items.length);
      for (final old in overflow) {
        await _storage.deleteFile(old.originalPath);
        await _storage.deleteFile(old.processedPath);
      }
    }

    await _save(items);
    return item;
  }

  Future<void> delete(String id) async {
    final items = getAll();
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final item = items.removeAt(index);
    await _storage.deleteFile(item.originalPath);
    await _storage.deleteFile(item.processedPath);
    await _save(items);
  }

  Future<void> clearAll() async {
    final items = getAll();
    for (final item in items) {
      await _storage.deleteFile(item.originalPath);
      await _storage.deleteFile(item.processedPath);
    }
    await _save([]);
  }

  Future<void> _save(List<HistoryItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  Map<String, List<HistoryItem>> grouped() {
    final all = getAll();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final today = <HistoryItem>[];
    final yesterday = <HistoryItem>[];
    final older = <HistoryItem>[];

    for (final item in all) {
      if (!item.createdAt.isBefore(todayStart)) {
        today.add(item);
      } else if (!item.createdAt.isBefore(yesterdayStart)) {
        yesterday.add(item);
      } else {
        older.add(item);
      }
    }

    return {
      'today': today,
      'yesterday': yesterday,
      'older': older,
    };
  }
}
