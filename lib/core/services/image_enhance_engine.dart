import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// High-impact on-device photo engine.
/// Tuned so Before/After shows a clear, premium difference.
class ImageEnhanceEngine {
  ImageEnhanceEngine._();

  static img.Image process({
    required img.Image source,
    required String operation,
    String? strength,
    int? upscaleFactor,
    int maxSide = 4096,
  }) {
    var image = source;
    if (image.width > maxSide || image.height > maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxSide : null,
        height: image.height > image.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }

    switch (operation) {
      case 'enhance':
        return enhance(image, strength ?? 'auto');
      case 'upscale':
        return upscale(image, upscaleFactor ?? 2, maxSide: maxSide);
      case 'restore':
        return restore(image);
      case 'colorize':
        return colorize(image);
      case 'denoise':
        return denoise(image, strength ?? 'medium');
      case 'sharpen':
        return sharpen(image, strength ?? 'medium');
      case 'cartoon':
        return cartoon(image, strength ?? 'classic');
      case 'portrait':
        return portrait(image);
      case 'backgroundChanger':
        return backgroundStudio(image, strength ?? 'blue');
      case 'ageChanger':
        return ageLook(image, strength ?? 'older');
      case 'artStyles':
        return artStyle(image, strength ?? 'oil');
      case 'filters':
        return filterPreset(image, strength ?? 'vivid');
      default:
        return enhance(image, 'auto');
    }
  }

  // ─── Creative styles ───────────────────────────────────────

  /// Soft professional cartoon / illustration look.
  /// Avoids crushing text & icons to solid black.
  /// Styles: soft | classic | bold | pop
  static img.Image cartoon(img.Image src, [String style = 'classic']) {
    final (:colors, :passes, :edgeAmt, :sat, :contrast, :band) = switch (style) {
      'soft' => (
          colors: 64,
          passes: 2,
          edgeAmt: 0.18,
          sat: 1.10,
          contrast: 1.06,
          band: 0,
        ),
      'bold' => (
          colors: 28,
          passes: 3,
          edgeAmt: 0.28,
          sat: 1.28,
          contrast: 1.14,
          band: 1,
        ),
      'pop' => (
          colors: 20,
          passes: 3,
          edgeAmt: 0.22,
          sat: 1.42,
          contrast: 1.18,
          band: 1,
        ),
      _ => (
          colors: 40,
          passes: 3,
          edgeAmt: 0.22,
          sat: 1.18,
          contrast: 1.10,
          band: 1,
        ),
    };

    // 1) Smooth first — melts fine text/icons into soft shapes
    var smooth = img.Image.from(src);
    for (var i = 0; i < passes; i++) {
      smooth = img.gaussianBlur(smooth, radius: 2);
    }
    smooth = img.gaussianBlur(smooth, radius: 1);

    // 2) Flat illustration palette (no dither)
    var flat = img.quantize(
      smooth,
      numberOfColors: colors,
      method: img.QuantizeMethod.octree,
      dither: img.DitherKernel.none,
    );
    if (flat.hasPalette) {
      flat = flat.convert(numChannels: 3);
    }

    // 3) Optional soft cel banding on luminance
    if (band > 0) {
      flat = _celBand(flat, steps: style == 'pop' ? 6 : 8);
    }

    flat = img.adjustColor(
      flat,
      saturation: sat,
      contrast: contrast,
      brightness: 1.03,
    );

    // 4) Soft contour from smoothed edges — never pure black
    if (edgeAmt > 0) {
      flat = _softInkOutline(flat, smooth, amount: edgeAmt);
    }

    return softClip(flat);
  }

  /// Soft luminance banding for a painted / cel look.
  static img.Image _celBand(img.Image src, {int steps = 8}) {
    final out = img.Image.from(src);
    final s = steps.clamp(4, 16);
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        final yv = 0.299 * r + 0.587 * g + 0.114 * b;
        final band = ((yv / 255.0) * s).round().clamp(0, s) / s;
        final target = band * 255.0;
        final delta = target - yv;
        const mix = 0.55;
        out.setPixelRgba(
          x,
          y,
          (r + delta * mix).round().clamp(0, 255),
          (g + delta * mix).round().clamp(0, 255),
          (b + delta * mix).round().clamp(0, 255),
          p.a.toInt(),
        );
      }
    }
    return out;
  }

  /// Thin soft ink — mixes toward deep ink color, capped so icons stay readable.
  static img.Image _softInkOutline(
    img.Image color,
    img.Image smoothSrc, {
    required double amount,
  }) {
    final gray = img.grayscale(img.Image.from(smoothSrc));
    final edges = img.sobel(gray, amount: 1);
    final out = img.Image.from(color);
    final maxC = math.max(1.0, edges.maxChannelValue.toDouble());

    const inkR = 28.0;
    const inkG = 32.0;
    const inkB = 48.0;

    for (var y = 1; y < out.height - 1; y++) {
      for (var x = 1; x < out.width - 1; x++) {
        final mag = edges.getPixel(x, y).luminance / maxC;
        if (mag < 0.38) continue;

        final n = edges.getPixel(x, y - 1).luminance / maxC;
        final s = edges.getPixel(x, y + 1).luminance / maxC;
        final w = edges.getPixel(x - 1, y).luminance / maxC;
        final e = edges.getPixel(x + 1, y).luminance / maxC;
        final isRidge = mag >= n && mag >= s || mag >= w && mag >= e;
        if (!isRidge) continue;

        final t = ((mag - 0.38) / 0.62).clamp(0.0, 1.0);
        final mix = (t * amount * 0.85).clamp(0.0, 0.42);

        final p = out.getPixel(x, y);
        out.setPixelRgba(
          x,
          y,
          (p.r + (inkR - p.r) * mix).round().clamp(0, 255),
          (p.g + (inkG - p.g) * mix).round().clamp(0, 255),
          (p.b + (inkB - p.b) * mix).round().clamp(0, 255),
          p.a.toInt(),
        );
      }
    }
    return out;
  }

  static img.Image portrait(img.Image src) {
    var out = img.gaussianBlur(src, radius: 1);
    out = applySCurve(out, amount: 0.18);
    out = vibrance(out, amount: 0.2);
    out = img.adjustColor(
      out,
      contrast: 1.06,
      brightness: 1.04,
      saturation: 1.05,
    );
    // Soft vignette for studio feel
    final cx = out.width / 2.0;
    final cy = out.height / 2.0;
    final maxD = math.sqrt(cx * cx + cy * cy);
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / maxD;
        final v = (1.0 - (d * d * 0.35)).clamp(0.7, 1.0);
        out.setPixelRgba(
          x,
          y,
          (p.r * v).round().clamp(0, 255),
          (p.g * v).round().clamp(0, 255),
          (p.b * v).round().clamp(0, 255),
          p.a.toInt(),
        );
      }
    }
    return softClip(out);
  }

  static img.Image backgroundStudio(img.Image src, String colorKey) {
    final bg = _studioBgRgb(colorKey);
    var soft = img.gaussianBlur(src, radius: 8);
    final out = img.Image.from(src);
    final cx = src.width / 2.0;
    final cy = src.height / 2.0;
    final maxD = math.sqrt(cx * cx + cy * cy);
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final p = src.getPixel(x, y);
        final b = soft.getPixel(x, y);
        final edge =
            ((p.r - b.r).abs() + (p.g - b.g).abs() + (p.b - b.b).abs()) / 3;
        final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / maxD;
        // Outer soft areas lean toward studio color
        final t = ((d - 0.35) / 0.55).clamp(0.0, 1.0) *
            (1.0 - (edge / 60).clamp(0.0, 1.0));
        out.setPixelRgba(
          x,
          y,
          (p.r + (bg[0] - p.r) * t).round().clamp(0, 255),
          (p.g + (bg[1] - p.g) * t).round().clamp(0, 255),
          (p.b + (bg[2] - p.b) * t).round().clamp(0, 255),
          p.a.toInt(),
        );
      }
    }
    return softClip(enhance(out, 'light'));
  }

  static List<int> _studioBgRgb(String colorKey) {
    return switch (colorKey) {
      'white' => [245, 246, 250],
      'black' => [28, 30, 36],
      'gray' => [210, 214, 222],
      'charcoal' => [72, 78, 90],
      'beige' => [236, 224, 206],
      'cream' => [255, 248, 230],
      'brown' => [140, 98, 70],
      'red' => [230, 70, 70],
      'coral' => [255, 127, 110],
      'orange' => [255, 152, 70],
      'yellow' => [255, 214, 80],
      'lime' => [170, 220, 90],
      'green' => [90, 190, 130],
      'mint' => [160, 230, 210],
      'teal' => [50, 175, 170],
      'cyan' => [90, 210, 235],
      'sky' => [150, 200, 255],
      'blue' => [120, 150, 255],
      'navy' => [40, 70, 140],
      'indigo' => [90, 90, 200],
      'purple' => [160, 110, 230],
      'lavender' => [210, 190, 255],
      'pink' => [255, 182, 210],
      'magenta' => [230, 80, 170],
      'maroon' => [140, 45, 70],
      'gold' => [230, 190, 100],
      _ => [120, 150, 255],
    };
  }

  static img.Image ageLook(img.Image src, String mode) {
    var out = img.Image.from(src);
    if (mode == 'younger') {
      out = img.gaussianBlur(out, radius: 1);
      out = img.adjustColor(out, brightness: 1.06, saturation: 1.08, contrast: 0.98);
      out = vibrance(out, amount: 0.15);
    } else {
      out = img.adjustColor(out, saturation: 0.72, contrast: 1.08, brightness: 0.97);
      // Warm aged tint
      for (var y = 0; y < out.height; y++) {
        for (var x = 0; x < out.width; x++) {
          final p = out.getPixel(x, y);
          out.setPixelRgba(
            x,
            y,
            (p.r * 1.05).round().clamp(0, 255),
            (p.g * 0.98).round().clamp(0, 255),
            (p.b * 0.88).round().clamp(0, 255),
            p.a.toInt(),
          );
        }
      }
      out = localClarity(out, amount: 0.25);
    }
    return softClip(out);
  }

  static img.Image artStyle(img.Image src, String style) {
    switch (style) {
      case 'sketch':
        final gray = img.grayscale(src);
        final edges = img.sobel(gray);
        var out = img.Image.from(edges);
        out = img.invert(out);
        return softClip(out);
      case 'pop':
        var out = img.quantize(src, numberOfColors: 12);
        out = img.adjustColor(out, saturation: 1.45, contrast: 1.2);
        return softClip(out);
      default: // oil
        var out = img.gaussianBlur(src, radius: 2);
        out = img.quantize(out, numberOfColors: 40);
        out = img.adjustColor(out, saturation: 1.15, contrast: 1.1);
        out = unsharpMask(out, radius: 1, amount: 0.6, threshold: 6);
        return softClip(out);
    }
  }

  static img.Image filterPreset(img.Image src, String preset) {
    switch (preset) {
      case 'mono':
        return softClip(img.adjustColor(img.grayscale(src), contrast: 1.12));
      case 'warm':
        var warm = img.Image.from(src);
        for (var y = 0; y < warm.height; y++) {
          for (var x = 0; x < warm.width; x++) {
            final p = warm.getPixel(x, y);
            warm.setPixelRgba(
              x,
              y,
              (p.r * 1.08).round().clamp(0, 255),
              (p.g * 1.02).round().clamp(0, 255),
              (p.b * 0.9).round().clamp(0, 255),
              p.a.toInt(),
            );
          }
        }
        return softClip(img.adjustColor(warm, saturation: 1.08, contrast: 1.05));
      case 'cool':
        var out = img.Image.from(src);
        for (var y = 0; y < out.height; y++) {
          for (var x = 0; x < out.width; x++) {
            final p = out.getPixel(x, y);
            out.setPixelRgba(
              x,
              y,
              (p.r * 0.92).round().clamp(0, 255),
              (p.g * 0.98).round().clamp(0, 255),
              (p.b * 1.08).round().clamp(0, 255),
              p.a.toInt(),
            );
          }
        }
        return softClip(out);
      default: // vivid
        return softClip(
          vibrance(
            img.adjustColor(src, contrast: 1.1, saturation: 1.18),
            amount: 0.25,
          ),
        );
    }
  }

  // ─── Enhance ───────────────────────────────────────────────

  static img.Image enhance(img.Image src, String strength) {
    final level = switch (strength) {
      'light' => 0.72,
      'strong' => 1.35,
      'standard' => 1.05,
      _ => 1.15, // auto — clearly visible
    };

    var out = autoLevels(src, lowPct: 0.012, highPct: 0.988);
    out = applySCurve(out, amount: 0.22 * level);
    out = localClarity(out, amount: 0.45 * level);
    out = vibrance(out, amount: 0.38 * level);
    out = img.adjustColor(
      out,
      contrast: 1.0 + 0.12 * level,
      brightness: 1.0 + 0.03 * level,
      saturation: 1.0 + 0.08 * level,
    );
    out = unsharpMask(out, radius: 1, amount: 0.85 * level, threshold: 4);
    return softClip(out);
  }

  // ─── Upscale ───────────────────────────────────────────────

  static img.Image upscale(img.Image src, int factor, {int maxSide = 4096}) {
    final f = factor.clamp(2, 4);
    final steps = f >= 4 ? <int>[2, 2] : <int>[f];
    var out = src;

    for (final step in steps) {
      final tw = (out.width * step).clamp(1, maxSide);
      final th = (out.height * step).clamp(1, maxSide);
      out = img.copyResize(
        out,
        width: tw,
        height: th,
        interpolation: img.Interpolation.cubic,
      );
      out = unsharpMask(out, radius: 1, amount: 1.2, threshold: 2);
      out = localClarity(out, amount: 0.3);
    }

    out = vibrance(out, amount: 0.22);
    out = img.adjustColor(out, contrast: 1.1, saturation: 1.08);
    out = unsharpMask(out, radius: 1, amount: 0.75, threshold: 3);
    return softClip(out);
  }

  // ─── Restore ───────────────────────────────────────────────

  static img.Image restore(img.Image src) {
    // Soft denoise → rebuild contrast → punch details / faces.
    var out = edgeAwareSmooth(src, blurRadius: 2, detail: 0.55);
    out = autoLevels(out, lowPct: 0.02, highPct: 0.98);
    out = applySCurve(out, amount: 0.28);
    out = localClarity(out, amount: 0.55);
    out = vibrance(out, amount: 0.25);
    out = unsharpMask(out, radius: 1, amount: 1.25, threshold: 3);
    out = img.adjustColor(
      out,
      contrast: 1.14,
      brightness: 1.04,
      saturation: 1.1,
    );
    return softClip(out);
  }

  // ─── Colorize ──────────────────────────────────────────────

  static img.Image colorize(img.Image src) {
    final gray = img.grayscale(src);
    final out = img.Image(width: gray.width, height: gray.height);
    final h = gray.height.toDouble();

    for (var y = 0; y < gray.height; y++) {
      final vPos = y / h; // 0 top → 1 bottom
      for (var x = 0; x < gray.width; x++) {
        final p = gray.getPixel(x, y);
        final lum = p.r / 255.0;

        // Zone colors (shadows / mid / highlights)
        final shadow = _rgb(35, 55, 95);
        final mid = _rgb(190, 145, 115); // skin / warm earth
        final hi = _rgb(245, 235, 210);

        late List<double> base;
        if (lum < 0.35) {
          final t = lum / 0.35;
          base = _lerpRgb(shadow, mid, _smooth(t));
        } else if (lum < 0.72) {
          final t = (lum - 0.35) / 0.37;
          base = _lerpRgb(mid, hi, _smooth(t));
        } else {
          final t = (lum - 0.72) / 0.28;
          base = _lerpRgb(hi, _rgb(255, 252, 245), _smooth(t));
        }

        // Sky bias on bright upper region
        if (vPos < 0.42 && lum > 0.45) {
          final sky = _rgb(110, 165, 230);
          final skyMix = (1 - vPos / 0.42) * ((lum - 0.45) / 0.55).clamp(0, 1);
          base = _lerpRgb(base, sky, skyMix * 0.55);
        }

        // Foliage bias on mid tones in lower half
        if (vPos > 0.45 && lum > 0.25 && lum < 0.7) {
          final green = _rgb(70, 130, 75);
          final gMix = ((lum - 0.25) / 0.45).clamp(0, 1) * (vPos - 0.45);
          base = _lerpRgb(base, green, gMix * 0.35);
        }

        // Preserve luminance structure
        final targetLum = 0.2126 * base[0] + 0.7152 * base[1] + 0.0722 * base[2];
        final scale = targetLum < 1e-3 ? 1.0 : (lum * 255) / targetLum;
        var r = (base[0] * scale).clamp(0, 255);
        var g = (base[1] * scale).clamp(0, 255);
        var b = (base[2] * scale).clamp(0, 255);

        out.setPixelRgb(x, y, r.round(), g.round(), b.round());
      }
    }

    var colored = vibrance(out, amount: 0.45);
    colored = applySCurve(colored, amount: 0.18);
    colored = unsharpMask(colored, radius: 1, amount: 0.7, threshold: 4);
    return softClip(colored);
  }

  // ─── Denoise ───────────────────────────────────────────────

  static img.Image denoise(img.Image src, String strength) {
    final blurR = switch (strength) {
      'low' => 1,
      'high' => 3,
      _ => 2,
    };
    final detailKeep = switch (strength) {
      'low' => 0.7,
      'high' => 0.4,
      _ => 0.55,
    };
    var out = edgeAwareSmooth(src, blurRadius: blurR, detail: detailKeep);
    out = vibrance(out, amount: 0.12);
    out = unsharpMask(out, radius: 1, amount: 0.55, threshold: 6);
    return softClip(out);
  }

  // ─── Sharpen ───────────────────────────────────────────────

  static img.Image sharpen(img.Image src, String strength) {
    final amount = switch (strength) {
      'low' => 0.9,
      'high' => 1.85,
      _ => 1.35,
    };
    var out = unsharpMask(src, radius: 1, amount: amount, threshold: 2);
    out = localClarity(out, amount: 0.2 * amount);
    out = img.adjustColor(out, contrast: 1.0 + 0.06 * amount);
    return softClip(out);
  }

  // ─── Core operators ────────────────────────────────────────

  static img.Image autoLevels(
    img.Image src, {
    double lowPct = 0.02,
    double highPct = 0.98,
  }) {
    final hist = List<int>.filled(256, 0);
    var count = 0;
    for (final p in src) {
      final y = (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b).round().clamp(0, 255);
      hist[y]++;
      count++;
    }
    if (count == 0) return src;

    final lowTarget = (count * lowPct).round();
    final highTarget = (count * highPct).round();
    var acc = 0;
    var low = 0;
    var high = 255;
    for (var i = 0; i < 256; i++) {
      acc += hist[i];
      if (acc >= lowTarget) {
        low = i;
        break;
      }
    }
    acc = 0;
    for (var i = 255; i >= 0; i--) {
      acc += hist[i];
      if (acc >= (count - highTarget)) {
        high = i;
        break;
      }
    }
    if (high <= low + 8) return src;

    final out = img.Image.from(src);
    final scale = 255.0 / (high - low);
    for (final p in out) {
      p
        ..r = ((p.r - low) * scale).round().clamp(0, 255)
        ..g = ((p.g - low) * scale).round().clamp(0, 255)
        ..b = ((p.b - low) * scale).round().clamp(0, 255);
    }
    return out;
  }

  static img.Image applySCurve(img.Image src, {required double amount}) {
    final out = img.Image.from(src);
    final a = amount.clamp(0.0, 1.5);
    for (final p in out) {
      p
        ..r = _sCurveChannel(p.r, a)
        ..g = _sCurveChannel(p.g, a)
        ..b = _sCurveChannel(p.b, a);
    }
    return out;
  }

  static int _sCurveChannel(num v, double amount) {
    final x = (v / 255.0).clamp(0.0, 1.0);
    // Contrast S-curve around midtones
    final y = x + amount * (x - x * x) * (0.5 - x) * 4;
    return (y.clamp(0.0, 1.0) * 255).round();
  }

  static img.Image vibrance(img.Image src, {required double amount}) {
    final out = img.Image.from(src);
    final a = amount.clamp(0.0, 2.0);
    for (final p in out) {
      final r = p.r.toDouble();
      final g = p.g.toDouble();
      final b = p.b.toDouble();
      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      final sat = maxC < 1e-3 ? 0.0 : (maxC - minC) / maxC;
      // Boost muted colors more (vibrance), protect already vivid.
      final boost = a * (1.0 - sat);
      final avg = (r + g + b) / 3.0;
      p
        ..r = (r + (r - avg) * boost).round().clamp(0, 255)
        ..g = (g + (g - avg) * boost).round().clamp(0, 255)
        ..b = (b + (b - avg) * boost).round().clamp(0, 255);
    }
    return out;
  }

  static img.Image unsharpMask(
    img.Image src, {
    required int radius,
    required double amount,
    required int threshold,
  }) {
    final blurred = img.gaussianBlur(src, radius: radius);
    final out = img.Image.from(src);
    final it = out.iterator;
    final bit = blurred.iterator;
    while (it.moveNext() && bit.moveNext()) {
      final o = it.current;
      final b = bit.current;
      o
        ..r = _unsharp(o.r, b.r, amount, threshold)
        ..g = _unsharp(o.g, b.g, amount, threshold)
        ..b = _unsharp(o.b, b.b, amount, threshold);
    }
    return out;
  }

  static int _unsharp(num orig, num blur, double amount, int threshold) {
    final diff = orig - blur;
    if (diff.abs() < threshold) return orig.round().clamp(0, 255);
    return (orig + diff * amount).round().clamp(0, 255);
  }

  /// Midtone local contrast (clarity).
  static img.Image localClarity(img.Image src, {required double amount}) {
    final blurred = img.gaussianBlur(src, radius: 3);
    final out = img.Image.from(src);
    final a = amount.clamp(0.0, 1.5);
    final it = out.iterator;
    final bit = blurred.iterator;
    while (it.moveNext() && bit.moveNext()) {
      final o = it.current;
      final b = bit.current;
      // Only punch midtones
      final lum = (0.2126 * o.r + 0.7152 * o.g + 0.0722 * o.b) / 255.0;
      final mid = 1.0 - (lum - 0.5).abs() * 2; // peak at 0.5
      final w = a * mid.clamp(0.0, 1.0);
      o
        ..r = (o.r + (o.r - b.r) * w).round().clamp(0, 255)
        ..g = (o.g + (o.g - b.g) * w).round().clamp(0, 255)
        ..b = (o.b + (o.b - b.b) * w).round().clamp(0, 255);
    }
    return out;
  }

  /// Blur flats, keep edges — better than plain gaussian denoise.
  static img.Image edgeAwareSmooth(
    img.Image src, {
    required int blurRadius,
    required double detail,
  }) {
    final blurred = img.gaussianBlur(src, radius: blurRadius);
    final out = img.Image.from(src);
    final d = detail.clamp(0.0, 1.0);
    final it = out.iterator;
    final bit = blurred.iterator;
    while (it.moveNext() && bit.moveNext()) {
      final o = it.current;
      final b = bit.current;
      final edge = ((o.r - b.r).abs() + (o.g - b.g).abs() + (o.b - b.b).abs()) / 3.0;
      final edgeW = (edge / 28.0).clamp(0.0, 1.0);
      final keep = d + (1 - d) * edgeW;
      o
        ..r = (b.r * (1 - keep) + o.r * keep).round().clamp(0, 255)
        ..g = (b.g * (1 - keep) + o.g * keep).round().clamp(0, 255)
        ..b = (b.b * (1 - keep) + o.b * keep).round().clamp(0, 255);
    }
    return out;
  }

  static img.Image softClip(img.Image src) {
    final out = img.Image.from(src);
    for (final p in out) {
      p
        ..r = _soft(p.r)
        ..g = _soft(p.g)
        ..b = _soft(p.b);
    }
    return out;
  }

  static int _soft(num v) {
    // Gentle shoulder to avoid harsh clipping look
    final x = v.clamp(0, 255) / 255.0;
    final y = x < 0.94 ? x : 0.94 + (x - 0.94) * 0.55;
    return (y.clamp(0.0, 1.0) * 255).round();
  }

  static List<double> _rgb(int r, int g, int b) =>
      [r.toDouble(), g.toDouble(), b.toDouble()];

  static List<double> _lerpRgb(List<double> a, List<double> b, double t) {
    final tt = t.clamp(0.0, 1.0);
    return [
      a[0] + (b[0] - a[0]) * tt,
      a[1] + (b[1] - a[1]) * tt,
      a[2] + (b[2] - a[2]) * tt,
    ];
  }

  static double _smooth(double x) {
    final v = x.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }
}

/// Isolate entry — must be top-level for `compute`.
Map<String, dynamic> runEnhanceJob(Map<String, dynamic> job) {
  final bytes = job['bytes'] as Uint8List;
  final operation = job['operation'] as String;
  final strength = job['strength'] as String?;
  final factor = job['factor'] as int?;
  final maxSide = job['maxSide'] as int? ?? 4096;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return {'ok': false, 'error': 'decode'};
  }

  final result = ImageEnhanceEngine.process(
    source: decoded,
    operation: operation,
    strength: strength,
    upscaleFactor: factor,
    maxSide: maxSide,
  );

  final encoded = Uint8List.fromList(img.encodeJpg(result, quality: 95));
  return {'ok': true, 'bytes': encoded};
}
