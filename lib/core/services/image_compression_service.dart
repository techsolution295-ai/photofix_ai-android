import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';

class ImageCompressionService {
  static const _uuid = Uuid();

  /// Compresses large images before upload while preserving reasonable quality.
  Future<File> prepareForUpload(File source) async {
    final bytes = await source.readAsBytes();
    if (bytes.lengthInBytes < 2 * 1024 * 1024) {
      return source;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return source;

    var image = decoded;
    final maxDim = AppConfig.maxImageDimension;
    if (image.width > maxDim || image.height > maxDim) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxDim : null,
        height: image.height > image.width ? maxDim : null,
        interpolation: img.Interpolation.average,
      );
    }

    final quality = bytes.lengthInBytes > 8 * 1024 * 1024 ? 80 : 88;
    final encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'upload_${_uuid.v4()}.jpg'));
    await out.writeAsBytes(encoded, flush: true);
    return out;
  }

  Future<({int width, int height})?> getDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return (width: decoded.width, height: decoded.height);
    } catch (_) {
      return null;
    }
  }
}
