import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:photofix_ai/core/services/image_enhance_engine.dart';

void main() {
  img.Image sample() {
    final image = img.Image(width: 64, height: 64);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        image.setPixelRgba(x, y, x * 4, y * 3, 120, 255);
      }
    }
    return image;
  }

  test('creative style operations process without error', () {
    final ops = [
      'cartoon',
      'portrait',
      'backgroundChanger',
      'ageChanger',
      'artStyles',
      'filters',
    ];
    for (final op in ops) {
      final out = ImageEnhanceEngine.process(
        source: sample(),
        operation: op,
        strength: op == 'ageChanger'
            ? 'younger'
            : op == 'artStyles'
                ? 'sketch'
                : op == 'filters'
                    ? 'warm'
                    : op == 'backgroundChanger'
                        ? 'pink'
                        : op == 'cartoon'
                            ? 'classic'
                            : null,
      );
      expect(out.width, greaterThan(0), reason: op);
      final bytes = Uint8List.fromList(img.encodeJpg(out, quality: 90));
      expect(bytes.isNotEmpty, isTrue, reason: op);
    }
  });

  test('cartoon styles produce visible output', () {
    for (final style in ['soft', 'classic', 'bold', 'pop']) {
      final out = ImageEnhanceEngine.process(
        source: sample(),
        operation: 'cartoon',
        strength: style,
      );
      expect(out.width, 64, reason: style);
      expect(out.height, 64, reason: style);
      final bytes = Uint8List.fromList(img.encodeJpg(out, quality: 90));
      expect(bytes.length, greaterThan(100), reason: style);
    }
  });
}
