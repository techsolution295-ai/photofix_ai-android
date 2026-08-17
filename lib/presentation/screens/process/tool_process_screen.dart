import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/image_compression_service.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_models.dart';
import '../../providers/ai_processing_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/media_widgets.dart';

/// Shared AI tool screen — fully free, no ads / Pro gates.
class ToolProcessScreen extends StatefulWidget {
  const ToolProcessScreen({
    super.key,
    required this.title,
    required this.operation,
    required this.actionLabel,
    this.description,
    this.initialImagePath,
    this.optionsBuilder,
    this.resolveParams,
  });

  final String title;
  final String? description;
  final AiOperation operation;
  final String actionLabel;
  final String? initialImagePath;
  final Widget Function(
    BuildContext context,
    void Function(VoidCallback fn) setState,
  )? optionsBuilder;
  final ({String? strength, int? upscaleFactor, Map<String, dynamic> options})
      Function()? resolveParams;

  @override
  State<ToolProcessScreen> createState() => _ToolProcessScreenState();
}

class _ToolProcessScreenState extends State<ToolProcessScreen> {
  String? _imagePath;
  ({int width, int height})? _dims;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
    if (_imagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_imagePath != null) _loadDims(_imagePath!);
      });
    }
  }

  Future<void> _loadDims(String path) async {
    if (!mounted) return;
    final compression = context.read<ImageCompressionService>();
    final dims = await compression.getDimensions(File(path));
    if (mounted) setState(() => _dims = dims);
  }

  Future<void> _pick({required bool camera}) async {
    final picker = context.read<PhotoPickerService>();
    final analytics = context.read<AnalyticsService>();
    try {
      final file =
          camera ? await picker.takePhoto() : await picker.pickFromGallery();
      if (file == null || !mounted) return;
      setState(() => _imagePath = file.path);
      await analytics.logEvent(
        AnalyticsEvents.photoSelected,
        {'source': camera ? 'camera' : 'gallery'},
      );
      await _loadDims(file.path);
    } on AiException catch (e) {
      if (!mounted) return;
      if (e.code == 'camera_permanently_denied') {
        await openAppSettings();
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  Future<void> _process() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first.')),
      );
      return;
    }

    final history = context.read<HistoryProvider>();
    final processing = context.read<AiProcessingProvider>();

    final params = widget.resolveParams?.call() ??
        (strength: null, upscaleFactor: null, options: <String, dynamic>{});

    final ok = await processing.run(
      image: File(_imagePath!),
      op: widget.operation,
      strength: params.strength,
      upscaleFactor: params.upscaleFactor,
      options: params.options,
    );

    if (!mounted) return;
    if (!ok) return;

    final args = processing.resultArgs!;
    await history.add(
      operation: args.operation,
      originalPath: args.originalPath,
      processedPath: args.processedPath,
      isPro: true,
    );

    if (!mounted) return;
    await Navigator.of(context).pushNamed(RouteNames.result, arguments: args);
    processing.reset();
  }

  String get _cleanActionLabel =>
      widget.actionLabel.replaceAll(RegExp(r'[^\w\s&/-]+'), '').trim();

  @override
  Widget build(BuildContext context) {
    final processing = context.watch<AiProcessingProvider>();
    final isBusy = processing.phase == ProcessingPhase.uploading ||
        processing.phase == ProcessingPhase.processing ||
        processing.phase == ProcessingPhase.validating;
    final hasImage = _imagePath != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ToolHeader(
              title: widget.title,
              subtitle: widget.description,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: isBusy && hasImage
                    ? ProcessingOverlay(
                        imagePath: _imagePath!,
                        message: processing.statusMessage,
                      )
                    : processing.phase == ProcessingPhase.error
                        ? ErrorView(
                            message: processing.errorMessage ??
                                AppStrings.processingFailed,
                            onRetry: _process,
                          )
                        : hasImage
                            ? _PhotoPreview(
                                path: _imagePath!,
                                dims: _dims,
                                onChange: () => _pick(camera: false),
                              )
                            : _SelectPhotoPanel(
                                onGallery: () => _pick(camera: false),
                                onCamera: () => _pick(camera: true),
                              ),
              ),
            ),
            if (!isBusy) ...[
              if (widget.optionsBuilder != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _OptionsCard(
                    child: widget.optionsBuilder!(context, setState),
                  ),
                ),
              _BottomActions(
                hasImage: hasImage,
                actionLabel: _cleanActionLabel,
                onGallery: () => _pick(camera: false),
                onCamera: () => _pick(camera: true),
                onProcess: _process,
              ),
            ] else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────

class _ToolHeader extends StatelessWidget {
  const _ToolHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              padding: const EdgeInsets.only(top: 10, right: 8),
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
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
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
    );
  }
}

// ─── Empty select panel ───────────────────────────────────────

class _SelectPhotoPanel extends StatelessWidget {
  const _SelectPhotoPanel({
    required this.onGallery,
    required this.onCamera,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Add a photo to continue',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Pick from gallery or take a new photo to start AI processing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Color(0xFF8B90A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: onGallery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    onTap: onCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F0FF),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo preview ────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.path,
    required this.dims,
    required this.onChange,
  });

  final String path;
  final ({int width, int height})? dims;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEEF0F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (dims != null)
          Positioned(
            left: 10,
            top: 10,
            child: _MetaChip(label: '${dims!.width} × ${dims!.height}'),
          ),
        Positioned(
          right: 10,
          top: 10,
          child: Material(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onChange,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Options card ─────────────────────────────────────────────

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEEF0F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Bottom actions ───────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.hasImage,
    required this.actionLabel,
    required this.onGallery,
    required this.onCamera,
    required this.onProcess,
  });

  final bool hasImage;
  final String actionLabel;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onProcess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            Row(
              children: [
                Expanded(
                  child: _MiniAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniAction(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera',
                    onTap: onCamera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasImage ? onProcess : onGallery,
                  borderRadius: BorderRadius.circular(6),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasImage
                              ? Icons.auto_awesome_rounded
                              : Icons.add_photo_alternate_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasImage ? actionLabel : 'Select Photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
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

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEEF0F6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A1D2E)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
