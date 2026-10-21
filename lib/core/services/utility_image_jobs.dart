import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Rotate, compress, convert, and collage — must stay top-level for [compute].
Map<String, dynamic> runUtilityJob(Map<String, dynamic> args) {
  try {
    switch (args['op'] as String) {
      case 'rotate':
        return _ok(_rotate(args));
      case 'compress':
        return _ok(_compress(args));
      case 'format':
        return _format(args);
      case 'collage':
        return _ok(_collage(args));
      default:
        return {'ok': false, 'error': 'op'};
    }
  } catch (e) {
    return {'ok': false, 'error': e.toString()};
  }
}

Map<String, dynamic> _ok(Uint8List bytes, [String ext = 'jpg']) {
  return {'ok': true, 'bytes': bytes, 'ext': ext};
}

img.Image _decodeOriented(Uint8List bytes) {
  final raw = img.decodeImage(bytes);
  if (raw == null) {
    throw StateError('decode');
  }
  return img.bakeOrientation(raw);
}

img.Image _limit(img.Image image, int maxSide) {
  if (image.width <= maxSide && image.height <= maxSide) return image;
  return img.copyResize(
    image,
    width: image.width >= image.height ? maxSide : null,
    height: image.height > image.width ? maxSide : null,
    interpolation: img.Interpolation.average,
  );
}

Uint8List _rotate(Map<String, dynamic> args) {
  var image = _limit(_decodeOriented(args['bytes'] as Uint8List), 4096);
  final turns = (args['turns'] as int) % 4;
  for (var i = 0; i < turns; i++) {
    image = img.copyRotate(image, angle: 90);
  }
  if (args['flipH'] == true) {
    image = img.flipHorizontal(image);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

Uint8List _compress(Map<String, dynamic> args) {
  final image = _limit(_decodeOriented(args['bytes'] as Uint8List), 4096);
  final quality = (args['quality'] as int).clamp(20, 95);
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

Map<String, dynamic> _format(Map<String, dynamic> args) {
  final image = _limit(_decodeOriented(args['bytes'] as Uint8List), 4096);
  switch (args['format'] as String) {
    case 'png':
      return _ok(Uint8List.fromList(img.encodePng(image)), 'png');
    case 'webp':
      // This build stores WEBP as a high-quality JPEG.
      return _ok(Uint8List.fromList(img.encodeJpg(image, quality: 92)));
    default:
      return _ok(Uint8List.fromList(img.encodeJpg(image, quality: 95)));
  }
}

Uint8List _collage(Map<String, dynamic> args) {
  final sources = args['images'] as List;
  final decoded = <img.Image>[];
  for (final item in sources.take(4)) {
    decoded.add(_limit(_decodeOriented(item as Uint8List), 1600));
  }
  if (decoded.length < 2) {
    throw StateError('decode');
  }

  const cell = 640;
  final count = decoded.length;
  final cols = count <= 1 ? 1 : 2;
  final rows = count <= 2 ? 1 : 2;
  final canvas = img.Image(width: cell * cols, height: cell * rows);
  img.fill(canvas, color: img.ColorRgb8(247, 248, 252));

  for (var i = 0; i < count; i++) {
    final resized = img.copyResize(
      decoded[i],
      width: cell,
      height: cell,
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      canvas,
      resized,
      dstX: (i % cols) * cell,
      dstY: (i ~/ cols) * cell,
    );
  }
  return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
}
