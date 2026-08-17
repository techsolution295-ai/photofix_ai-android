import 'package:flutter/material.dart';

import '../../core/services/history_repository.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/models.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repo);

  final HistoryRepository _repo;

  List<HistoryItem> get items => _repo.getAll();
  Map<String, List<HistoryItem>> get grouped => _repo.grouped();
  bool get isEmpty => items.isEmpty;

  Future<void> add({
    required AiOperation operation,
    required String originalPath,
    required String processedPath,
    required bool isPro,
  }) async {
    await _repo.add(
      operation: operation,
      originalPath: originalPath,
      processedPath: processedPath,
      isPro: isPro,
    );
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
