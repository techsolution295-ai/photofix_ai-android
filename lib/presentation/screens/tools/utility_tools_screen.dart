import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';
import '../../providers/history_provider.dart';

/// Shared shell for local utility editors.
class _UtilityShell extends StatelessWidget {
  const _UtilityShell({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D2E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF8B90A5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pickPhoto(BuildContext context) async {
  final picker = context.read<PhotoPickerService>();
  try {
    final file = await picker.pickFromGallery();
    return file?.path;
  } on AiException catch (e) {
    if (!context.mounted) return null;
    if (e.code == 'camera_permanently_denied') {
      await openAppSettings();
      return null;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.userMessage)));
    return null;
  }
}

Future<File> _writeTemp(Uint8List bytes, String ext) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'util_${const Uuid().v4()}.$ext'));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> _openResult(
  BuildContext context, {
  required String original,
  required String processed,
  required AiOperation op,
}) async {
  final storage = context.read<ImageStorageService>();
  final orig = await storage.persistOriginal(original);
  final saved = await storage.persistProcessed(
    remoteUrl: null,
    localPath: processed,
    operation: op.name,
  );
  if (!context.mounted) return;
  await context.read<HistoryProvider>().add(
        operation: op,
        originalPath: orig,
        processedPath: saved,
        isPro: true,
      );
  if (!context.mounted) return;
  await Navigator.of(context).pushNamed(
    RouteNames.result,
    arguments: ResultArgs(
      originalPath: orig,
      processedPath: saved,
      operation: op,
    ),
  );
}

// ─── Shared option pills ──────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  final List<(String id, String label)> items;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _OptionPill(
                label: items[i].$2,
                selected: selectedId == items[i].$1,
                onTap: () => onChanged(items[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEEF0F6)),
      ),
      child: child,
    );
  }
}

// ─── Rotate ───────────────────────────────────────────────────

class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  String? _path;
  int _turns = 0;
  bool _flipH = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _path = widget.args?.initialImagePath;
  }

  Future<void> _run() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await File(_path!).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('decode');
      for (var i = 0; i < _turns % 4; i++) {
        decoded = img.copyRotate(decoded!, angle: 90);
      }
      if (_flipH) decoded = img.flipHorizontal(decoded!);
      final out = await _writeTemp(
        Uint8List.fromList(img.encodeJpg(decoded!, quality: 95)),
        'jpg',
      );
      if (!mounted) return;
      await _openResult(
        context,
        original: _path!,
        processed: out.path,
        op: AiOperation.rotate,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not rotate photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UtilityShell(
      title: 'Rotate',
      subtitle: 'Rotate or flip your photo before saving.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: Transform.rotate(
                angle: (_turns % 4) * (math.pi / 2),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(_flipH ? -1 : 1, 1, 1),
                  child: _Preview(path: _path, onPick: _pick),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Panel(
              child: Row(
                children: [
                  Expanded(
                    child: _MiniTool(
                      icon: Icons.rotate_left_rounded,
                      label: 'Left',
                      onTap: () => setState(() => _turns = (_turns + 3) % 4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniTool(
                      icon: Icons.rotate_right_rounded,
                      label: 'Right',
                      onTap: () => setState(() => _turns = (_turns + 1) % 4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniTool(
                      icon: Icons.flip_rounded,
                      label: 'Flip',
                      active: _flipH,
                      onTap: () => setState(() => _flipH = !_flipH),
                    ),
                  ),
                ],
              ),
            ),
            _Actions(
              busy: _busy,
              hasImage: _path != null,
              onPick: _pick,
              onRun: _run,
              runLabel: 'Save Photo',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final pth = await _pickPhoto(context);
    if (pth != null) {
      setState(() {
        _path = pth;
        _turns = 0;
        _flipH = false;
      });
    }
  }
}

// ─── Compress ─────────────────────────────────────────────────

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  String? _path;
  double _quality = 70;
  bool _busy = false;
  int? _before;

  @override
  void initState() {
    super.initState();
    _path = widget.args?.initialImagePath;
    if (_path != null) {
      File(_path!).length().then((v) {
        if (mounted) setState(() => _before = v);
      });
    }
  }

  Future<void> _run() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await File(_path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('decode');
      final encoded =
          Uint8List.fromList(img.encodeJpg(decoded, quality: _quality.round()));
      final out = await _writeTemp(encoded, 'jpg');
      if (!mounted) return;
      await _openResult(
        context,
        original: _path!,
        processed: out.path,
        op: AiOperation.compress,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not compress photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _kb(int? b) => b == null ? '—' : '${(b / 1024).toStringAsFixed(0)} KB';

  @override
  Widget build(BuildContext context) {
    return _UtilityShell(
      title: 'Compress',
      subtitle: 'Reduce file size while keeping good quality.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(child: _Preview(path: _path, onPick: _pick)),
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Quality',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_quality.round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: const Color(0xFFE4E7F0),
                      overlayColor:
                          AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _quality,
                      min: 20,
                      max: 95,
                      onChanged: (v) => setState(() => _quality = v),
                    ),
                  ),
                  Text(
                    'Current size: ${_kb(_before)}',
                    style: const TextStyle(
                      color: Color(0xFF8B90A5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _Actions(
              busy: _busy,
              hasImage: _path != null,
              onPick: _pick,
              onRun: _run,
              runLabel: 'Compress',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final pth = await _pickPhoto(context);
    if (pth != null) {
      final len = await File(pth).length();
      setState(() {
        _path = pth;
        _before = len;
      });
    }
  }
}

// ─── Format convert ───────────────────────────────────────────

class FormatConvertScreen extends StatefulWidget {
  const FormatConvertScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<FormatConvertScreen> createState() => _FormatConvertScreenState();
}

class _FormatConvertScreenState extends State<FormatConvertScreen> {
  String? _path;
  String _format = 'jpg';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _path = widget.args?.initialImagePath;
  }

  Future<void> _run() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await File(_path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('decode');
      late Uint8List encoded;
      late String ext;
      switch (_format) {
        case 'png':
          encoded = Uint8List.fromList(img.encodePng(decoded));
          ext = 'png';
        case 'webp':
          // Device-safe high quality JPEG stand-in for WEBP.
          encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
          ext = 'jpg';
        default:
          encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
          ext = 'jpg';
      }
      final out = await _writeTemp(encoded, ext);
      if (!mounted) return;
      await _openResult(
        context,
        original: _path!,
        processed: out.path,
        op: AiOperation.formatConvert,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not convert format.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UtilityShell(
      title: 'Format Convert',
      subtitle: 'Convert your photo to JPG, PNG or WEBP.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(child: _Preview(path: _path, onPick: _pick)),
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output format',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B90A5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OptionRow(
                    items: const [
                      ('jpg', 'JPG'),
                      ('png', 'PNG'),
                      ('webp', 'WEBP'),
                    ],
                    selectedId: _format,
                    onChanged: (v) => setState(() => _format = v),
                  ),
                  if (_format == 'webp') ...[
                    const SizedBox(height: 10),
                    const Text(
                      'WEBP saves as high-quality JPG on this device build.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B90A5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _Actions(
              busy: _busy,
              hasImage: _path != null,
              onPick: _pick,
              onRun: _run,
              runLabel: 'Convert Format',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final pth = await _pickPhoto(context);
    if (pth != null) setState(() => _path = pth);
  }
}

// ─── Stickers & Text ──────────────────────────────────────────

class StickersTextScreen extends StatefulWidget {
  const StickersTextScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<StickersTextScreen> createState() => _StickersTextScreenState();
}

class _StickersTextScreenState extends State<StickersTextScreen> {
  String? _path;
  final _textCtrl = TextEditingController(text: 'PhotoFix AI');
  String _sticker = '✨';
  final _repaint = GlobalKey();
  bool _busy = false;

  static const _stickers = ['✨', '🔥', '❤️', '😎', '⭐'];

  @override
  void initState() {
    super.initState();
    _path = widget.args?.initialImagePath;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _repaint.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('capture');
      final out = await _writeTemp(data.buffer.asUint8List(), 'png');
      if (!mounted) return;
      await _openResult(
        context,
        original: _path!,
        processed: out.path,
        op: AiOperation.stickersText,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save stickers.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UtilityShell(
      title: 'Stickers & Text',
      subtitle: 'Add fun stickers and custom text on your photo.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: _path == null
                  ? _Preview(path: null, onPick: _pick)
                  : RepaintBoundary(
                      key: _repaint,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEEF0F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_path!), fit: BoxFit.contain),
                            Align(
                              alignment: const Alignment(0.72, -0.58),
                              child: Text(
                                _sticker,
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0, 0.62),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _textCtrl.text.isEmpty
                                      ? 'Your text'
                                      : _textCtrl.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: _textCtrl.text.isEmpty ? 0.55 : 1,
                                    ),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 8,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (_path != null) ...[
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter text…',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sticker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B90A5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: Row(
                        children: [
                          for (var i = 0; i < _stickers.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _OptionPill(
                                label: _stickers[i],
                                selected: _sticker == _stickers[i],
                                onTap: () =>
                                    setState(() => _sticker = _stickers[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _Actions(
              busy: _busy,
              hasImage: _path != null,
              onPick: _pick,
              onRun: _run,
              runLabel: 'Save Design',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final pth = await _pickPhoto(context);
    if (pth != null) setState(() => _path = pth);
  }
}

// ─── Collage ──────────────────────────────────────────────────

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final List<String> _paths = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.args?.initialImagePath;
    if (initial != null) _paths.add(initial);
  }

  Future<void> _add() async {
    if (_paths.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos in a collage.')),
      );
      return;
    }
    final pth = await _pickPhoto(context);
    if (pth != null) setState(() => _paths.add(pth));
  }

  void _remove(int i) => setState(() => _paths.removeAt(i));

  Future<void> _run() async {
    if (_paths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 photos.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final decoded = <img.Image>[];
      for (final path in _paths.take(4)) {
        final bytes = await File(path).readAsBytes();
        final d = img.decodeImage(bytes);
        if (d != null) decoded.add(img.bakeOrientation(d));
      }
      if (decoded.length < 2) throw Exception('decode');

      const cell = 640;
      final count = decoded.length;
      final cols = count == 3 ? 2 : (count <= 2 ? count : 2);
      final rows = count <= 2 ? 1 : 2;
      final canvas = img.Image(width: cell * cols, height: cell * rows);
      img.fill(canvas, color: img.ColorRgb8(247, 248, 252));

      for (var i = 0; i < count; i++) {
        final r = i ~/ cols;
        final c = i % cols;
        // For 3 photos: last one spans remaining? keep simple grid; 3rd in bottom-left
        final w = cell;
        final h = cell;
        final resized = img.copyResize(
          decoded[i],
          width: w,
          height: h,
          interpolation: img.Interpolation.average,
          maintainAspect: false,
        );
        img.compositeImage(canvas, resized, dstX: c * cell, dstY: r * cell);
      }

      final out = await _writeTemp(
        Uint8List.fromList(img.encodeJpg(canvas, quality: 92)),
        'jpg',
      );
      if (!mounted) return;
      await _openResult(
        context,
        original: _paths.first,
        processed: out.path,
        op: AiOperation.collage,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create collage.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UtilityShell(
      title: 'Collage Maker',
      subtitle: 'Combine 2–4 photos into one collage.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, i) {
                  if (i < _paths.length) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEEF0F6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(
                            File(_paths[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: () => _remove(i),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: _paths.length < 4 ? _add : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFE4E7F0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add photo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF8B90A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_paths.length}/4 photos selected',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B90A5),
              ),
            ),
            _Actions(
              busy: _busy,
              hasImage: _paths.length >= 2,
              onPick: _add,
              onRun: _run,
              runLabel: 'Make Collage',
              pickLabel: 'Add Photo',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI bits ───────────────────────────────────────────

class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.onPick});
  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: path == null ? onPick : null,
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
          clipBehavior: Clip.antiAlias,
          child: path == null
              ? Column(
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
                        Icons.add_photo_alternate_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Add a photo to continue',
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
                )
              : Image.file(File(path!), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _MiniTool extends StatelessWidget {
  const _MiniTool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFEEE8FF) : const Color(0xFFF3F4F8),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? AppColors.primary : const Color(0xFF1A1D2E),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : const Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.busy,
    required this.hasImage,
    required this.onPick,
    required this.onRun,
    required this.runLabel,
    this.pickLabel = 'Choose Photo',
  });

  final bool busy;
  final bool hasImage;
  final VoidCallback onPick;
  final VoidCallback onRun;
  final String runLabel;
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: busy ? null : onPick,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEEF0F6)),
                  ),
                  child: Text(
                    pickLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: hasImage && !busy ? AppColors.primaryGradient : null,
                color: hasImage && !busy ? null : const Color(0xFFD8DCE8),
                boxShadow: hasImage && !busy
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.26),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (!hasImage || busy) ? null : onRun,
                  borderRadius: BorderRadius.circular(6),
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            runLabel,
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white
                                  : const Color(0xFF8B90A5),
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
    );
  }
}
