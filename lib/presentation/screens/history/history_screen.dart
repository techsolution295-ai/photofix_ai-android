import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _filters = <(String, AiOperation?)>[
    ('All', null),
    ('Enhance', AiOperation.enhance),
    ('Upscale', AiOperation.upscale),
    ('Restore', AiOperation.restore),
    ('Colorize', AiOperation.colorize),
  ];

  AiOperation? _filter;

  List<HistoryItem> _filtered(List<HistoryItem> all) {
    if (_filter == null) return all;
    return all.where((e) => e.operation == _filter).toList();
  }

  Map<String, List<HistoryItem>> _sections(List<HistoryItem> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final map = <String, List<HistoryItem>>{};

    for (final item in items) {
      final d = item.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      final key = !day.isBefore(todayStart)
          ? 'Today'
          : !day.isBefore(yesterdayStart)
              ? 'Yesterday'
              : DateFormat('MMM d, yyyy').format(day);
      (map[key] ??= []).add(item);
    }
    return map;
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.clearAll),
        content: const Text(
          'Delete all history items? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.clearAll),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<HistoryProvider>().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final items = _filtered(history.items);
    final sections = _sections(items);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D2E),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (!history.isEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final active = _filter == f.$2;
                    return Material(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => setState(() => _filter = f.$2),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : const Color(0xFFE2E5EF),
                            ),
                          ),
                          child: Text(
                            f.$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              height: 1,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF1A1D2E),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? const _HistoryEmpty()
                  : items.isEmpty
                      ? const _FilterEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: sections.length,
                          itemBuilder: (context, i) {
                            final key = sections.keys.elementAt(i);
                            final list = sections[key]!;
                            return _DateSection(title: key, items: list);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'No history yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D2E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your enhanced and edited photos will appear here after you process them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF8B90A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_off_rounded,
              size: 56,
              color: Color(0xFF9AA0B4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No items for this filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another filter or process a new photo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Color(0xFF8B90A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({required this.title, required this.items});
  final String title;
  final List<HistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: -0.2,
            ),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(item: item),
            )),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final HistoryItem item;

  String get _statusWord {
    switch (item.operation) {
      case AiOperation.enhance:
        return 'Enhanced';
      case AiOperation.upscale:
        return 'Upscaled';
      case AiOperation.restore:
        return 'Restored';
      case AiOperation.colorize:
        return 'Colorized';
      case AiOperation.denoise:
        return 'Denoised';
      case AiOperation.sharpen:
        return 'Sharpened';
      default:
        return 'Done';
    }
  }

  String get _title {
    switch (item.operation) {
      case AiOperation.enhance:
        return 'Enhanced Photo';
      case AiOperation.upscale:
        return 'HD Upscale';
      case AiOperation.restore:
        return 'Restored Photo';
      case AiOperation.colorize:
        return 'Colorized Photo';
      case AiOperation.denoise:
        return 'Noise Removal';
      case AiOperation.sharpen:
        return 'Sharpen Photo';
      default:
        return item.operation.displayName;
    }
  }

  Future<String> _sizeLabel() async {
    try {
      final bytes = await File(item.processedPath).length();
      if (bytes >= 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } catch (_) {
      return '—';
    }
  }

  void _open(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteNames.result,
      arguments: ResultArgs(
        originalPath: item.originalPath,
        processedPath: item.processedPath,
        operation: item.operation,
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final storage = context.read<ImageStorageService>();
    final analytics = context.read<AnalyticsService>();
    try {
      await storage.saveToGallery(item.processedPath);
      await analytics.logEvent(AnalyticsEvents.resultSaved);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccess)),
      );
    } on AiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.userMessage)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveFailed)),
      );
    }
  }

  Future<void> _menu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _HistoryActionSheet(),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'open':
        _open(context);
      case 'save':
        await _download(context);
      case 'share':
        await context
            .read<ImageStorageService>()
            .shareImage(item.processedPath);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete item?'),
            content: const Text(
              'This photo will be removed from history permanently.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          await context.read<HistoryProvider>().delete(item.id);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(item.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF0F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BeforeAfterThumb(
                  originalPath: item.originalPath,
                  processedPath: item.processedPath,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.15,
                                  color: Color(0xFF1A1D2E),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _menu(context),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                  color: Color(0xFF8B90A5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$time • $_statusWord',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A6078),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<String>(
                          future: _sizeLabel(),
                          builder: (context, snap) => Text(
                            snap.data ?? '…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.2,
                              color: Color(0xFF9AA0B5),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Material(
                            color: const Color(0xFFF1F3F8),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _download(context),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.download_rounded,
                                  size: 17,
                                  color: Color(0xFF5A6078),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _BeforeAfterThumb extends StatelessWidget {
  const _BeforeAfterThumb({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  child: Image.file(
                    File(originalPath),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    cacheWidth: 240,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFE8EAF2)),
                  ),
                ),
                Expanded(
                  child: Image.file(
                    File(processedPath),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    cacheWidth: 240,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFDDE1EC)),
                  ),
                ),
              ],
            ),
            Align(
              child: Container(
                width: 2,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Align(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 14,
                  color: Color(0xFF1A1D2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryActionSheet extends StatelessWidget {
  const _HistoryActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              _SimpleAction(
                title: 'View result',
                onTap: () => Navigator.pop(context, 'open'),
              ),
              _SimpleAction(
                title: 'Save to gallery',
                onTap: () => Navigator.pop(context, 'save'),
              ),
              _SimpleAction(
                title: 'Share',
                onTap: () => Navigator.pop(context, 'share'),
              ),
              const Divider(height: 1, color: Color(0xFFEEF0F6)),
              _SimpleAction(
                title: 'Delete',
                danger: true,
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleAction extends StatelessWidget {
  const _SimpleAction({
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: danger
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF1A1D2E),
            ),
          ),
        ),
      ),
    );
  }
}
