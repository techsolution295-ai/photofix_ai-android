import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_strings.dart';
import '../../domain/models/ai_models.dart';

class ImageStorageService {
  ImageStorageService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final _uuid = const Uuid();

  Future<Directory> _historyDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'history'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> persistProcessed({
    required String? remoteUrl,
    required String? localPath,
    required String operation,
  }) async {
    final dir = await _historyDir();
    final filename = '${operation}_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.jpg';
    final dest = File(p.join(dir.path, filename));

    if (localPath != null && await File(localPath).exists()) {
      await File(localPath).copy(dest.path);
      return dest.path;
    }

    if (remoteUrl == null || remoteUrl.isEmpty) {
      throw AiException(AppStrings.saveFailed, code: 'no_source');
    }

    final response = await _dio.get<List<int>>(
      remoteUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    await dest.writeAsBytes(response.data ?? [], flush: true);
    return dest.path;
  }

  Future<String> persistProcessedBytes(
    Uint8List bytes, {
    required String operation,
    String ext = 'jpg',
  }) async {
    final dir = await _historyDir();
    final filename =
        '${operation}_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$ext';
    final dest = File(p.join(dir.path, filename));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  Future<String> persistOriginal(String sourcePath) async {
    final dir = await _historyDir();
    final filename =
        'orig_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}${p.extension(sourcePath)}';
    final dest = File(p.join(dir.path, filename));
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> saveToGallery(String path) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw AiException(AppStrings.saveFailed, code: 'permission');
        }
      }
      await Gal.putImage(path, album: 'PhotoFix AI');
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(AppStrings.saveFailed, cause: e);
    }
  }

  Future<void> shareImage(String path) async {
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Enhanced with PhotoFix AI',
    );
  }

  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
