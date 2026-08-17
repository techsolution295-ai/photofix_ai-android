import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/media_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.args});

  final ResultArgs args;

  Future<void> _save(BuildContext context) async {
    final storage = context.read<ImageStorageService>();
    final analytics = context.read<AnalyticsService>();
    try {
      await storage.saveToGallery(args.processedPath);
      await analytics.logEvent(AnalyticsEvents.resultSaved);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccess)),
      );
    } on AiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveFailed)),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final storage = context.read<ImageStorageService>();
    final analytics = context.read<AnalyticsService>();
    await storage.shareImage(args.processedPath);
    await analytics.logEvent(AnalyticsEvents.resultShared);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(args.operation.displayName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                AppStrings.enhancementComplete,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BeforeAfterSlider(
                  beforePath: args.originalPath,
                  afterPath: args.processedPath,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: AppStrings.saveToGallery,
                icon: Icons.download,
                onPressed: () => _save(context),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: AppStrings.share,
                onPressed: () => _share(context),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.main,
                          (r) => false,
                        );
                        Navigator.of(context).pushNamed(
                          RouteNames.enhance,
                        );
                      },
                      child: const Text(AppStrings.enhanceAnother),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.main,
                          (r) => false,
                        );
                      },
                      child: const Text(AppStrings.goHome),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
