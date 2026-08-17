import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/config/app_config.dart';
import 'package:photofix_ai/core/services/history_repository.dart';
import 'package:photofix_ai/core/services/image_storage_service.dart';
import 'package:photofix_ai/domain/models/ai_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryRepository', () {
    late HistoryRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = HistoryRepository(prefs, ImageStorageService());
    });

    test('adds and lists items', () async {
      await repo.add(
        operation: AiOperation.enhance,
        originalPath: '/tmp/a.jpg',
        processedPath: '/tmp/b.jpg',
        isPro: true,
      );
      expect(repo.getAll(), hasLength(1));
      expect(repo.getAll().first.operation, AiOperation.enhance);
    });

    test('enforces free history limit', () async {
      for (var i = 0; i < AppConfig.freeHistoryLimit + 3; i++) {
        await repo.add(
          operation: AiOperation.enhance,
          originalPath: '/tmp/o$i.jpg',
          processedPath: '/tmp/p$i.jpg',
          isPro: false,
        );
      }
      expect(repo.getAll().length, AppConfig.freeHistoryLimit);
    });

    test('delete removes item', () async {
      final item = await repo.add(
        operation: AiOperation.sharpen,
        originalPath: '/tmp/o.jpg',
        processedPath: '/tmp/p.jpg',
        isPro: true,
      );
      await repo.delete(item.id);
      expect(repo.getAll(), isEmpty);
    });

    test('persists JSON round-trip shape', () async {
      await repo.add(
        operation: AiOperation.restore,
        originalPath: '/tmp/o.jpg',
        processedPath: '/tmp/p.jpg',
        isPro: true,
      );
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('history_items_v1')!;
      final decoded = jsonDecode(raw) as List<dynamic>;
      expect(decoded.first['operation'], 'restore');
    });
  });
}
