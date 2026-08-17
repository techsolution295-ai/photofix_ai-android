import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_models.dart';
import '../config/app_config.dart';
import '../constants/app_strings.dart';
import 'ai_service.dart';

/// Development-only mock. Applies a local image adjustment so UI can be tested.
/// Never used silently in production (see [AppConfig.shouldUseMockAi]).
class MockAiService implements AiService {
  final _uuid = const Uuid();

  @override
  bool get requiresNetwork => false;

  @override
  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  }) =>
      _process(image, AiOperation.enhance, strength: strength);

  @override
  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  }) =>
      _process(image, AiOperation.upscale, factor: factor);

  @override
  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options = const {},
  }) =>
      _process(image, AiOperation.restore);

  @override
  Future<AiProcessingResponse> colorizePhoto({required File image}) =>
      _process(image, AiOperation.colorize);

  @override
  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  }) =>
      _process(image, AiOperation.denoise, strength: strength);

  @override
  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  }) =>
      _process(image, AiOperation.sharpen, strength: strength);

  @override
  Future<AiProcessingResponse> getProcessingStatus(String jobId) async {
    return AiProcessingResponse(
      success: true,
      jobId: jobId,
      status: AiJobStatus.completed,
    );
  }

  @override
  Future<AiProcessingResponse> process(AiProcessingRequest request) {
    return _process(
      File(request.imagePath),
      request.operation,
      strength: request.strength,
      factor: request.upscaleFactor,
    );
  }

  Future<AiProcessingResponse> _process(
    File image,
    AiOperation operation, {
    String? strength,
    int? factor,
  }) async {
    if (AppConfig.isProduction) {
      throw AiException(
        'Mock AI is disabled in production. Configure API_BASE_URL.',
        code: 'mock_forbidden',
      );
    }

    if (!await image.exists()) {
      throw AiException(AppStrings.invalidImage, code: 'invalid_image');
    }

    // Simulate network/upload latency for realistic UI states.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw AiException(AppStrings.invalidImage, code: 'decode');
    }

    img.Image result = decoded;

    switch (operation) {
      case AiOperation.enhance:
        result = img.adjustColor(
          result,
          contrast: strength == 'strong'
              ? 1.15
              : strength == 'light'
                  ? 1.05
                  : 1.1,
          saturation: 1.08,
          brightness: 1.03,
        );
        result = img.convolution(
          result,
          filter: [0, -0.5, 0, -0.5, 3, -0.5, 0, -0.5, 0],
        );
      case AiOperation.upscale:
        final f = factor ?? 2;
        result = img.copyResize(
          result,
          width: result.width * f,
          height: result.height * f,
          interpolation: img.Interpolation.cubic,
        );
      case AiOperation.restore:
        result = img.adjustColor(result, contrast: 1.12, brightness: 1.05);
        result = img.gaussianBlur(result, radius: 1);
        result = img.convolution(
          result,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        );
      case AiOperation.colorize:
        // Pseudo-colorize for mock: apply a warm color cast over grayscale.
        result = img.grayscale(result);
        result = img.colorOffset(result, red: 18, green: 8, blue: -6);
        result = img.adjustColor(result, saturation: 1.25, contrast: 1.08);
      case AiOperation.denoise:
        final radius = strength == 'high'
            ? 2
            : strength == 'low'
                ? 1
                : 1;
        result = img.gaussianBlur(result, radius: radius);
      case AiOperation.sharpen:
        final amount = strength == 'high'
            ? 5.0
            : strength == 'low'
                ? 3.5
                : 4.0;
        result = img.convolution(
          result,
          filter: [0, -1, 0, -1, amount, -1, 0, -1, 0],
        );
      case AiOperation.cartoon:
      case AiOperation.portrait:
      case AiOperation.backgroundChanger:
      case AiOperation.stickersText:
      case AiOperation.ageChanger:
      case AiOperation.artStyles:
      case AiOperation.filters:
      case AiOperation.collage:
      case AiOperation.crop:
      case AiOperation.rotate:
      case AiOperation.compress:
      case AiOperation.formatConvert:
        result = img.adjustColor(result, contrast: 1.1, saturation: 1.1);
    }

    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'mock_${_uuid.v4()}.jpg');
    final encoded = Uint8List.fromList(img.encodeJpg(result, quality: 92));
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded, flush: true);

    return AiProcessingResponse(
      success: true,
      jobId: _uuid.v4(),
      localImagePath: outPath,
      message: 'Mock processing complete (development only)',
      status: AiJobStatus.completed,
    );
  }
}
