import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/image_compression_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/network_service.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/models.dart';

enum ProcessingPhase { idle, validating, uploading, processing, success, error }

class AiProcessingProvider extends ChangeNotifier {
  AiProcessingProvider({
    required AiService aiService,
    required NetworkService network,
    required ImageCompressionService compression,
    required ImageStorageService storage,
    required AnalyticsService analytics,
  })  : _ai = aiService,
        _network = network,
        _compression = compression,
        _storage = storage,
        _analytics = analytics;

  final AiService _ai;
  final NetworkService _network;
  final ImageCompressionService _compression;
  final ImageStorageService _storage;
  final AnalyticsService _analytics;

  ProcessingPhase phase = ProcessingPhase.idle;
  String statusMessage = '';
  String? errorMessage;
  String? originalPath;
  String? processedPath;
  AiOperation? operation;

  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _messages = [
    AppStrings.preparingModel,
    AppStrings.enhancingDetails,
    AppStrings.improvingQuality,
    AppStrings.finalizing,
  ];

  Future<bool> run({
    required File image,
    required AiOperation op,
    String? strength,
    int? upscaleFactor,
    Map<String, dynamic> options = const {},
  }) async {
    phase = ProcessingPhase.validating;
    errorMessage = null;
    operation = op;
    originalPath = image.path;
    processedPath = null;
    notifyListeners();

    if (_ai.requiresNetwork) {
      final online = await _network.checkOnline();
      if (!online) {
        phase = ProcessingPhase.error;
        errorMessage = AppStrings.offlineRequired;
        notifyListeners();
        return false;
      }
    }

    _startRotatingMessages();
    phase = ProcessingPhase.uploading;
    notifyListeners();

    await _analytics.logEvent(AnalyticsEvents.enhancementStarted, {
      'operation': op.name,
    });

    try {
      // Keep max quality for on-device processing; compress only for cloud upload.
      final prepared = _ai.requiresNetwork
          ? await _compression.prepareForUpload(image)
          : image;
      phase = ProcessingPhase.processing;
      notifyListeners();

      final response = await _ai.process(
        AiProcessingRequest(
          imagePath: prepared.path,
          operation: op,
          strength: strength,
          upscaleFactor: upscaleFactor,
          options: options,
        ),
      );

      String? local = response.localImagePath;
      if (local == null && response.imageUrl != null) {
        local = await _storage.persistProcessed(
          remoteUrl: response.imageUrl,
          localPath: null,
          operation: op.name,
        );
      }
      if (local == null) {
        throw AiException(AppStrings.processingFailed, code: 'no_result');
      }

      // Persist original copy for history/comparison
      final origCopy = await _storage.persistOriginal(image.path);

      originalPath = origCopy;
      processedPath = local;
      phase = ProcessingPhase.success;
      _stopRotatingMessages();
      await _analytics.logEvent(AnalyticsEvents.enhancementCompleted, {
        'operation': op.name,
      });
      notifyListeners();
      return true;
    } on AiException catch (e) {
      phase = ProcessingPhase.error;
      errorMessage = e.userMessage;
      _stopRotatingMessages();
      await _analytics.logEvent(AnalyticsEvents.enhancementFailed, {
        'operation': op.name,
        'code': e.code ?? '',
      });
      notifyListeners();
      return false;
    } catch (e) {
      phase = ProcessingPhase.error;
      errorMessage = AppStrings.processingFailed;
      _stopRotatingMessages();
      await _analytics.logEvent(AnalyticsEvents.enhancementFailed, {
        'operation': op.name,
      });
      notifyListeners();
      return false;
    }
  }

  ResultArgs? get resultArgs {
    if (originalPath == null || processedPath == null || operation == null) {
      return null;
    }
    return ResultArgs(
      originalPath: originalPath!,
      processedPath: processedPath!,
      operation: operation!,
    );
  }

  void reset() {
    _stopRotatingMessages();
    phase = ProcessingPhase.idle;
    statusMessage = '';
    errorMessage = null;
    notifyListeners();
  }

  void _startRotatingMessages() {
    _messageIndex = 0;
    statusMessage = _messages[0];
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      _messageIndex = (_messageIndex + 1) % _messages.length;
      statusMessage = _messages[_messageIndex];
      notifyListeners();
    });
  }

  void _stopRotatingMessages() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  @override
  void dispose() {
    _stopRotatingMessages();
    super.dispose();
  }
}
