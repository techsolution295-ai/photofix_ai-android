import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'image_enhance_engine.dart';

/// Runs crop + light polish off the UI thread.
Map<String, dynamic> runCropJob(Map<String, dynamic> args) {
  try {
    final bytes = args['bytes'] as Uint8List;
    final x = args['x'] as int;
    final y = args['y'] as int;
    final w = args['w'] as int;
    final h = args['h'] as int;

    final raw = img.decodeImage(bytes);
    if (raw == null) {
      return {'ok': false, 'error': 'decode'};
    }

    final decoded = img.bakeOrientation(raw);
    final cx = x.clamp(0, decoded.width - 1);
    final cy = y.clamp(0, decoded.height - 1);
    final cw = w.clamp(1, decoded.width - cx);
    final ch = h.clamp(1, decoded.height - cy);

    var cropped = img.copyCrop(
      decoded,
      x: cx,
      y: cy,
      width: cw,
      height: ch,
    );

    // Crisp, clean crop — subtle polish without over-sharpening.
    cropped = img.adjustColor(
      cropped,
      contrast: 1.05,
      saturation: 1.03,
      brightness: 1.01,
    );
    cropped = ImageEnhanceEngine.unsharpMask(
      cropped,
      radius: 1,
      amount: 0.55,
      threshold: 3,
    );
    cropped = ImageEnhanceEngine.softClip(cropped);

    final out = Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
    return {'ok': true, 'bytes': out};
  } catch (e) {
    return {'ok': false, 'error': e.toString()};
  }
}
