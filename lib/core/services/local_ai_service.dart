import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_models.dart';
import '../config/app_config.dart';
import '../constants/app_strings.dart';
import 'ai_service.dart';
import 'image_enhance_engine.dart';

/// On-device high-quality processing — no API key required.
class LocalAiService implements AiService {
  final _uuid = const Uuid();

  @override
  bool get requiresNetwork => false;

  @override
  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  }) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.enhance,
          strength: strength,
        ),
      );

  @override
  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  }) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.upscale,
          upscaleFactor: factor,
        ),
      );

  @override
  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options = const {},
  }) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.restore,
          options: options,
        ),
      );

  @override
  Future<AiProcessingResponse> colorizePhoto({required File image}) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.colorize,
        ),
      );

  @override
  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  }) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.denoise,
          strength: strength,
        ),
      );

  @override
  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  }) =>
      process(
        AiProcessingRequest(
          imagePath: image.path,
          operation: AiOperation.sharpen,
          strength: strength,
        ),
      );

  @override
  Future<AiProcessingResponse> getProcessingStatus(String jobId) async {
    return AiProcessingResponse(
      success: true,
      jobId: jobId,
      status: AiJobStatus.completed,
    );
  }

  @override
  Future<AiProcessingResponse> process(AiProcessingRequest request) async {
    final image = File(request.imagePath);
    if (!await image.exists()) {
      throw AiException(AppStrings.invalidImage, code: 'missing');
    }

    final bytes = await image.readAsBytes();

    // Heavy work off the UI isolate.
    final result = await compute(runEnhanceJob, <String, dynamic>{
      'bytes': bytes,
      'operation': request.operation.name,
      'strength': request.strength,
      'factor': request.upscaleFactor,
      'maxSide': AppConfig.maxImageDimension,
    });

    if (result['ok'] != true) {
      throw AiException(AppStrings.invalidImage, code: result['error']?.toString());
    }

    final outBytes = result['bytes'] as Uint8List;
    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'hq_${_uuid.v4()}.jpg'));
    await out.writeAsBytes(outBytes, flush: true);

    return AiProcessingResponse(
      success: true,
      jobId: _uuid.v4(),
      localImagePath: out.path,
      message: 'High-quality on-device processing complete',
      status: AiJobStatus.completed,
    );
  }
}

/// Uses OpenAI when a key exists; otherwise on-device [LocalAiService].
class HybridAiService implements AiService {
  HybridAiService({
    required AiService local,
    required AiService Function() cloudFactory,
    required bool Function() hasCloudKey,
  })  : _local = local,
        _cloudFactory = cloudFactory,
        _hasCloudKey = hasCloudKey;

  final AiService _local;
  final AiService Function() _cloudFactory;
  final bool Function() _hasCloudKey;

  AiService get _active => _hasCloudKey() ? _cloudFactory() : _local;

  @override
  bool get requiresNetwork => _hasCloudKey();

  @override
  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  }) =>
      _active.enhancePhoto(image: image, strength: strength);

  @override
  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  }) =>
      _active.upscalePhoto(image: image, factor: factor);

  @override
  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options = const {},
  }) =>
      _active.restorePhoto(image: image, options: options);

  @override
  Future<AiProcessingResponse> colorizePhoto({required File image}) =>
      _active.colorizePhoto(image: image);

  @override
  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  }) =>
      _active.removeNoise(image: image, strength: strength);

  @override
  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  }) =>
      _active.sharpenPhoto(image: image, strength: strength);

  @override
  Future<AiProcessingResponse> getProcessingStatus(String jobId) =>
      _active.getProcessingStatus(jobId);

  @override
  Future<AiProcessingResponse> process(AiProcessingRequest request) {
    // Creative styles are processed on-device for consistent free UX.
    if (request.operation.isCreativeStyle) {
      return _local.process(request);
    }
    return _active.process(request);
  }
}
