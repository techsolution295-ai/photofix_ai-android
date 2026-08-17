import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photofix_ai/core/services/image_enhance_engine.dart';

void main() {
  img.Image sample() {
    final image = img.Image(width: 64, height: 64);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final v = ((x + y) * 2).clamp(40, 200);
        image.setPixelRgb(x, y, v, v ~/ 2, 180 - v ~/ 3);
      }
    }
    return image;
  }

  test('enhance changes pixels visibly', () {
    final src = sample();
    final out = ImageEnhanceEngine.enhance(src, 'strong');
    expect(out.width, src.width);
    var changed = 0;
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final a = src.getPixel(x, y);
        final b = out.getPixel(x, y);
        if (a.r != b.r || a.g != b.g || a.b != b.b) changed++;
      }
    }
    expect(changed, greaterThan(500));
  });

  test('upscale 2x doubles size', () {
    final out = ImageEnhanceEngine.upscale(sample(), 2);
    expect(out.width, 128);
    expect(out.height, 128);
  });

  test('colorize produces non-gray output', () {
    final gray = img.grayscale(sample());
    final out = ImageEnhanceEngine.colorize(gray);
    var colorful = 0;
    for (final p in out) {
      if ((p.r - p.g).abs() > 8 || (p.g - p.b).abs() > 8) colorful++;
    }
    expect(colorful, greaterThan(100));
  });

  test('isolate job returns jpeg bytes', () {
    final bytes = Uint8List.fromList(img.encodeJpg(sample()));
    final result = runEnhanceJob({
      'bytes': bytes,
      'operation': 'enhance',
      'strength': 'auto',
      'maxSide': 512,
    });
    expect(result['ok'], isTrue);
    expect((result['bytes'] as Uint8List).length, greaterThan(100));
  });
}
