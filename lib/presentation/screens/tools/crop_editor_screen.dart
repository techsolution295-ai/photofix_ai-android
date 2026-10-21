import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/services/crop_engine.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/pro_chip.dart';

class _PreviewDecode {
  const _PreviewDecode(this.image, this.originalSize);
  final ui.Image image;
  final Size originalSize;
}

/// Decodes a display-sized preview and keeps the oriented original size
/// so crop coordinates still match the saved photo.
Future<_PreviewDecode> _decodePreview(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      const maxPreview = 1600;
      final rawW = descriptor.width;
      final rawH = descriptor.height;
      if (rawW < 1 || rawH < 1) {
        throw StateError('empty image');
      }
      final longSide = math.max(rawW, rawH);
      final codec = await descriptor.instantiateCodec(
        targetWidth: longSide > maxPreview && rawW >= rawH ? maxPreview : null,
        targetHeight: longSide > maxPreview && rawH > rawW ? maxPreview : null,
      );
      try {
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final rawAspect = rawW / rawH;
        final frameAspect = image.width / image.height;
        final swapped = rawW != rawH &&
            (rawAspect - frameAspect).abs() > 0.08 &&
            ((rawH / rawW) - frameAspect).abs() < 0.08;
        return _PreviewDecode(
          image,
          Size(
            (swapped ? rawH : rawW).toDouble(),
            (swapped ? rawW : rawH).toDouble(),
          ),
        );
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}

/// Professional interactive crop editor — drag, resize, aspect lock.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  String? _path;
  Uint8List? _bytes;
  ui.Image? _decoded;
  Size? _imageSize;

  /// Crop rect in image pixel coordinates.
  Rect? _crop;

  /// Free = null, otherwise locked ratio (w/h).
  double? _aspect = 1;

  bool _busy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.args?.initialImagePath;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(initial));
    }
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _path = path;
      _crop = null;
      _decoded?.dispose();
      _decoded = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final preview = await _decodePreview(bytes);
      if (!mounted) {
        preview.image.dispose();
        return;
      }
      setState(() {
        _bytes = bytes;
        _decoded = preview.image;
        _imageSize = preview.originalSize;
        _crop = _defaultCrop(preview.originalSize);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open photo.')),
      );
    }
  }

  Rect _defaultCrop(Size size) {
    final aspect = _aspect;
    if (aspect == null) {
      final insetX = size.width * 0.08;
      final insetY = size.height * 0.08;
      return Rect.fromLTRB(insetX, insetY, size.width - insetX, size.height - insetY);
    }
    double w;
    double h;
    if (size.width / size.height > aspect) {
      h = size.height * 0.84;
      w = h * aspect;
    } else {
      w = size.width * 0.84;
      h = w / aspect;
    }
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  void _applyAspect(double? aspect) {
    setState(() {
      _aspect = aspect;
      if (_imageSize != null) {
        _crop = _defaultCrop(_imageSize!);
      }
    });
  }

  Future<void> _pick() async {
    final picker = context.read<PhotoPickerService>();
    try {
      final file = await picker.pickFromGallery();
      if (file == null || !mounted) return;
      await _load(file.path);
    } on AiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  Future<void> _applyCrop() async {
    if (_busy ||
        _path == null ||
        _bytes == null ||
        _crop == null ||
        _imageSize == null) {
      return;
    }
    final iw = _imageSize!.width.round();
    final ih = _imageSize!.height.round();
    if (iw < 2 || ih < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This photo is too small to crop.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final crop = _crop!;
      final x = crop.left.round();
      final y = crop.top.round();
      final w = crop.width.round();
      final h = crop.height.round();

      final storage = context.read<ImageStorageService>();

      // Crop off UI thread + save original in parallel.
      final results = await Future.wait<Object>([
        compute(runCropJob, {
          'bytes': _bytes!,
          'x': x,
          'y': y,
          'w': w,
          'h': h,
        }),
        storage.persistOriginal(_path!),
      ]);

      final cropResult = results[0] as Map<String, dynamic>;
      if (cropResult['ok'] != true) throw Exception('crop');

      final encoded = cropResult['bytes'] as Uint8List;
      final orig = results[1] as String;

      if (!mounted) return;
      final processed = await storage.persistProcessedBytes(
        encoded,
        operation: AiOperation.crop.name,
      );

      if (!mounted) return;
      await context.read<HistoryProvider>().add(
            operation: AiOperation.crop,
            originalPath: orig,
            processedPath: processed,
            isPro: true,
          );
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        RouteNames.result,
        arguments: ResultArgs(
          originalPath: orig,
          processedPath: processed,
          operation: AiOperation.crop,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not crop photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _decoded != null && !_loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF1A1D2E),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crop',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D2E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Drag corners to resize · drag inside to move',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(0xFF8B90A5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: _busy ? null : _pick,
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!context.watch<SettingsProvider>().isPremium)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 8),
                      child: ProChip(),
                    ),
                ],
              ),
            ),
            const BannerAdWidget(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _decoded == null
                        ? _EmptyPick(onPick: _pick)
                        : Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFEEF0F6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _InteractiveCropView(
                                  image: _decoded!,
                                  imageSize: _imageSize!,
                                  crop: _crop!,
                                  aspect: _aspect,
                                  onChanged: (r) => _crop = r,
                                ),
                              ),
                              if (_busy)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(height: 14),
                                        Text(
                                          'Cropping photo…',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
            if (hasImage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aspect ratio',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B90A5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AspectRow(
                            items: const [
                              _AspectOption(null, 'Free'),
                              _AspectOption(1, '1:1'),
                              _AspectOption(4 / 5, '4:5'),
                              _AspectOption(3 / 4, '3:4'),
                            ],
                            selected: _aspect,
                            onSelect: _applyAspect,
                          ),
                          const SizedBox(height: 8),
                          _AspectRow(
                            items: const [
                              _AspectOption(16 / 9, '16:9'),
                              _AspectOption(9 / 16, '9:16'),
                            ],
                            selected: _aspect,
                            onSelect: _applyAspect,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: _busy ? null : AppColors.primaryGradient,
                          color: _busy ? const Color(0xFFD8DCE8) : null,
                          boxShadow: _busy
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.26),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _busy ? null : _applyCrop,
                            borderRadius: BorderRadius.circular(6),
                            child: Center(
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Apply Crop',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.26),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pick,
                        borderRadius: BorderRadius.circular(6),
                        child: const Center(
                          child: Text(
                            'Choose Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AspectOption {
  const _AspectOption(this.ratio, this.label);
  final double? ratio;
  final String label;
}

class _AspectRow extends StatelessWidget {
  const _AspectRow({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<_AspectOption> items;
  final double? selected;
  final ValueChanged<double?> onSelect;

  bool _isSelected(_AspectOption item) {
    if (item.ratio == null && selected == null) return true;
    if (item.ratio == null || selected == null) return false;
    return (item.ratio! - selected!).abs() < 0.001;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _AspectPill(
                label: items[i].label,
                selected: _isSelected(items[i]),
                onTap: () => onSelect(items[i].ratio),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AspectPill extends StatelessWidget {
  const _AspectPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : const Color(0xFFF3F4F8),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE4E7F0),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF5A6078),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPick extends StatelessWidget {
  const _EmptyPick({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEEF0F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.crop_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add a photo to crop',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap to choose from gallery',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8B90A5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Hit { none, move, tl, tr, bl, br, left, right, top, bottom }

class _InteractiveCropView extends StatefulWidget {
  const _InteractiveCropView({
    required this.image,
    required this.imageSize,
    required this.crop,
    required this.aspect,
    required this.onChanged,
  });

  final ui.Image image;
  final Size imageSize;
  final Rect crop;
  final double? aspect;
  final ValueChanged<Rect> onChanged;

  @override
  State<_InteractiveCropView> createState() => _InteractiveCropViewState();
}

class _InteractiveCropViewState extends State<_InteractiveCropView> {
  _Hit _hit = _Hit.none;
  Rect? _startCrop;
  Offset? _startLocal;
  late Rect _crop;

  @override
  void initState() {
    super.initState();
    _crop = widget.crop;
  }

  @override
  void didUpdateWidget(covariant _InteractiveCropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hit == _Hit.none && widget.crop != oldWidget.crop) {
      _crop = widget.crop;
    }
  }

  /// Fitted image rect inside the view.
  Rect _fitRect(Size view) {
    final sx = view.width / widget.imageSize.width;
    final sy = view.height / widget.imageSize.height;
    final s = math.min(sx, sy);
    final w = widget.imageSize.width * s;
    final h = widget.imageSize.height * s;
    return Rect.fromLTWH((view.width - w) / 2, (view.height - h) / 2, w, h);
  }

  Rect _cropToView(Rect crop, Rect fit) {
    return Rect.fromLTRB(
      fit.left + crop.left / widget.imageSize.width * fit.width,
      fit.top + crop.top / widget.imageSize.height * fit.height,
      fit.left + crop.right / widget.imageSize.width * fit.width,
      fit.top + crop.bottom / widget.imageSize.height * fit.height,
    );
  }

  Rect _clamp(Rect r) {
    final max = widget.imageSize;
    if (max.width < 2 || max.height < 2) {
      return Rect.fromLTWH(0, 0, math.max(max.width, 1), math.max(max.height, 1));
    }
    var left = math.min(r.left, r.right);
    var right = math.max(r.left, r.right);
    var top = math.min(r.top, r.bottom);
    var bottom = math.max(r.top, r.bottom);
    left = left.clamp(0.0, max.width - 1);
    top = top.clamp(0.0, max.height - 1);
    right = right.clamp(left + 1, max.width);
    bottom = bottom.clamp(top + 1, max.height);
    final minW = math.min(40.0, max.width);
    final minH = math.min(40.0, max.height);
    if (right - left < minW) {
      right = (left + minW).clamp(0.0, max.width);
      left = (right - minW).clamp(0.0, max.width);
    }
    if (bottom - top < minH) {
      bottom = (top + minH).clamp(0.0, max.height);
      top = (bottom - minH).clamp(0.0, max.height);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _applyAspect(Rect r, _Hit hit) {
    final aspect = widget.aspect;
    if (aspect == null || hit == _Hit.move || hit == _Hit.none) return r;

    var left = r.left;
    var top = r.top;
    var right = r.right;
    var bottom = r.bottom;
    var w = (right - left).abs();
    var h = (bottom - top).abs();

    if (hit == _Hit.left || hit == _Hit.right) {
      h = w / aspect;
      final cy = (top + bottom) / 2;
      top = cy - h / 2;
      bottom = cy + h / 2;
    } else if (hit == _Hit.top || hit == _Hit.bottom) {
      w = h * aspect;
      final cx = (left + right) / 2;
      left = cx - w / 2;
      right = cx + w / 2;
    } else if (hit == _Hit.tl || hit == _Hit.tr) {
      h = w / aspect;
      top = bottom - h;
    } else if (hit == _Hit.bl || hit == _Hit.br) {
      h = w / aspect;
      bottom = top + h;
    }

    return _clamp(Rect.fromLTRB(left, top, right, bottom));
  }

  _Hit _detectHit(Offset local, Rect cropView) {
    const handle = 28.0;
    bool near(Offset corner) => (local - corner).distance <= handle;

    if (near(cropView.topLeft)) return _Hit.tl;
    if (near(cropView.topRight)) return _Hit.tr;
    if (near(cropView.bottomLeft)) return _Hit.bl;
    if (near(cropView.bottomRight)) return _Hit.br;

    if ((local.dx - cropView.left).abs() <= handle &&
        local.dy >= cropView.top &&
        local.dy <= cropView.bottom) {
      return _Hit.left;
    }
    if ((local.dx - cropView.right).abs() <= handle &&
        local.dy >= cropView.top &&
        local.dy <= cropView.bottom) {
      return _Hit.right;
    }
    if ((local.dy - cropView.top).abs() <= handle &&
        local.dx >= cropView.left &&
        local.dx <= cropView.right) {
      return _Hit.top;
    }
    if ((local.dy - cropView.bottom).abs() <= handle &&
        local.dx >= cropView.left &&
        local.dx <= cropView.right) {
      return _Hit.bottom;
    }
    if (cropView.contains(local)) return _Hit.move;
    return _Hit.none;
  }

  void _onScaleStart(ScaleStartDetails d, Rect fit) {
    final cropView = _cropToView(_crop, fit);
    _hit = _detectHit(d.localFocalPoint, cropView);
    _startCrop = _crop;
    _startLocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Rect fit) {
    if (_hit == _Hit.none || _startCrop == null || _startLocal == null) return;
    if (fit.width < 1 || fit.height < 1) return;
    final deltaLocal = d.localFocalPoint - _startLocal!;
    final delta = Offset(
      deltaLocal.dx * widget.imageSize.width / fit.width,
      deltaLocal.dy * widget.imageSize.height / fit.height,
    );
    var r = _startCrop!;

    switch (_hit) {
      case _Hit.move:
        r = r.shift(delta);
        // Keep inside bounds without resizing.
        final max = widget.imageSize;
        var dx = 0.0;
        var dy = 0.0;
        if (r.left < 0) dx = -r.left;
        if (r.top < 0) dy = -r.top;
        if (r.right > max.width) dx = max.width - r.right;
        if (r.bottom > max.height) dy = max.height - r.bottom;
        r = r.shift(Offset(dx, dy));
      case _Hit.tl:
        r = Rect.fromLTRB(
          r.left + delta.dx,
          r.top + delta.dy,
          r.right,
          r.bottom,
        );
      case _Hit.tr:
        r = Rect.fromLTRB(
          r.left,
          r.top + delta.dy,
          r.right + delta.dx,
          r.bottom,
        );
      case _Hit.bl:
        r = Rect.fromLTRB(
          r.left + delta.dx,
          r.top,
          r.right,
          r.bottom + delta.dy,
        );
      case _Hit.br:
        r = Rect.fromLTRB(
          r.left,
          r.top,
          r.right + delta.dx,
          r.bottom + delta.dy,
        );
      case _Hit.left:
        r = Rect.fromLTRB(r.left + delta.dx, r.top, r.right, r.bottom);
      case _Hit.right:
        r = Rect.fromLTRB(r.left, r.top, r.right + delta.dx, r.bottom);
      case _Hit.top:
        r = Rect.fromLTRB(r.left, r.top + delta.dy, r.right, r.bottom);
      case _Hit.bottom:
        r = Rect.fromLTRB(r.left, r.top, r.right, r.bottom + delta.dy);
      case _Hit.none:
        return;
    }

    r = _clamp(r);
    if (widget.aspect != null && _hit != _Hit.move) {
      r = _applyAspect(r, _hit);
    }
    setState(() => _crop = r);
    widget.onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final view = Size(c.maxWidth, c.maxHeight);
        final fit = _fitRect(view);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) => _onScaleStart(d, fit),
          onScaleUpdate: (d) => _onScaleUpdate(d, fit),
          onScaleEnd: (_) {
            _hit = _Hit.none;
            _startCrop = null;
            _startLocal = null;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: view,
                  painter: _PhotoPainter(image: widget.image, fit: fit),
                ),
              ),
              CustomPaint(
                size: view,
                painter: _CropPainter(
                  fit: fit,
                  imageSize: widget.imageSize,
                  crop: _crop,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter({required this.image, required this.fit});

  final ui.Image image;
  final Rect fit;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: fit,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoPainter old) =>
      old.image != image || old.fit != fit;
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.fit,
    required this.imageSize,
    required this.crop,
  });

  final Rect fit;
  final Size imageSize;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final cropView = Rect.fromLTRB(
      fit.left + crop.left / imageSize.width * fit.width,
      fit.top + crop.top / imageSize.height * fit.height,
      fit.left + crop.right / imageSize.width * fit.width,
      fit.top + crop.bottom / imageSize.height * fit.height,
    );

    // Dim outside
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(cropView),
      ),
      dim,
    );

    // Border
    final border = Paint()
      ..color = const Color(0xFF6C4CF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRect(cropView, border);

    // Rule of thirds
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final dx = cropView.left + cropView.width * i / 3;
      final dy = cropView.top + cropView.height * i / 3;
      canvas.drawLine(
        Offset(dx, cropView.top),
        Offset(dx, cropView.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(cropView.left, dy),
        Offset(cropView.right, dy),
        grid,
      );
    }

    // Corner handles
    final handle = Paint()..color = const Color(0xFF6C4CF1);
    const hs = 18.0;
    const t = 3.5;
    void corner(Offset o, bool right, bool bottom) {
      final path = Path();
      if (!right && !bottom) {
        path
          ..moveTo(o.dx, o.dy + hs)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx + hs, o.dy);
      } else if (right && !bottom) {
        path
          ..moveTo(o.dx - hs, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + hs);
      } else if (!right && bottom) {
        path
          ..moveTo(o.dx, o.dy - hs)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx + hs, o.dy);
      } else {
        path
          ..moveTo(o.dx - hs, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy - hs);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = t
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(o, 4, handle);
    }

    corner(cropView.topLeft, false, false);
    corner(cropView.topRight, true, false);
    corner(cropView.bottomLeft, false, true);
    corner(cropView.bottomRight, true, true);
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.crop != crop || old.fit != fit;
}
