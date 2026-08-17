import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_models.dart';
import '../config/app_config.dart';
import '../constants/app_strings.dart';
import 'ai_service.dart';
import 'openai_key_store.dart';

/// Real AI processing via OpenAI Images Edits API (`/v1/images/edits`).
class OpenAiAiService implements AiService {
  OpenAiAiService(this._keys, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.openai.com',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 180),
                sendTimeout: const Duration(seconds: 180),
              ),
            );

  final OpenAiKeyStore _keys;
  final Dio _dio;
  final _uuid = const Uuid();

  @override
  bool get requiresNetwork => true;

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
    final apiKey = _keys.effectiveKey;
    if (apiKey == null) {
      throw AiException(
        'OpenAI API key missing. Add it in Profile → Settings.',
        code: 'no_api_key',
      );
    }

    final source = File(request.imagePath);
    if (!await source.exists()) {
      throw AiException(AppStrings.invalidImage, code: 'missing');
    }

    try {
      final prepared = await _prepareUpload(source);
      final prompt = _promptFor(request);
      final size = _outputSizeFor(prepared.width, prepared.height);

      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          prepared.file.path,
          filename: 'photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'model': AppConfig.openAiImageModel,
        'prompt': prompt,
        'n': '1',
        'size': size,
        'quality': 'high',
        'output_format': 'jpeg',
        'input_fidelity': 'high',
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/images/edits',
        data: form,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
          contentType: 'multipart/form-data',
        ),
      );

      final bytes = await _extractImageBytes(response.data);
      var outFile = await _writeTemp(bytes, 'openai');

      // For upscale, enlarge to target resolution after AI enhancement.
      if (request.operation == AiOperation.upscale) {
        final factor = request.upscaleFactor ?? 2;
        outFile = await _upscaleLocally(
          outFile,
          targetWidth: prepared.width * factor,
          targetHeight: prepared.height * factor,
        );
      }

      return AiProcessingResponse(
        success: true,
        jobId: _uuid.v4(),
        localImagePath: outFile.path,
        message: 'Processed with OpenAI',
        status: AiJobStatus.completed,
      );
    } on AiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      throw AiException(AppStrings.processingFailed, cause: e);
    }
  }

  String _promptFor(AiProcessingRequest request) {
    switch (request.operation) {
      case AiOperation.enhance:
        final level = request.strength ?? 'auto';
        return 'Professionally enhance this photograph. Improve sharpness, '
            'fine details, lighting, contrast and overall clarity while keeping '
            'the subject, identity, composition and realism unchanged. '
            'Enhancement strength: $level. Do not add new objects or text.';
      case AiOperation.upscale:
        return 'Enhance this photograph for high-resolution upscaling. '
            'Recover fine detail, reduce blur and compression artifacts, '
            'and keep faces and textures natural. Do not crop or change composition.';
      case AiOperation.restore:
        return 'Restore this old or damaged photograph. Remove scratches, dust, '
            'stains and tears where possible. Reduce blur, improve contrast, '
            'and recover facial details while preserving the original look and era. '
            'Do not invent unrelated people or scenes.';
      case AiOperation.colorize:
        return 'Colorize this black-and-white photograph with realistic, '
            'historically plausible natural colors. Keep identity, clothing '
            'shapes and composition unchanged. Avoid oversaturation.';
      case AiOperation.denoise:
        final level = request.strength ?? 'medium';
        return 'Remove digital noise, grain and low-light noise from this photo '
            'at $level strength. Preserve important detail and edges. '
            'Do not over-smooth faces or textures.';
      case AiOperation.sharpen:
        final level = request.strength ?? 'medium';
        return 'Sharpen this photograph at $level strength. Improve clarity and '
            'edge definition without creating halos or unnatural artifacts. '
            'Keep the image photorealistic.';
      case AiOperation.cartoon:
        return 'Transform this photograph into a clean cartoon / illustration '
            'style with bold shapes and smooth colors while keeping the subject recognizable.';
      case AiOperation.portrait:
        return 'Create a polished studio-quality portrait look: soft skin, '
            'balanced lighting, gentle background falloff. Keep identity unchanged.';
      case AiOperation.backgroundChanger:
        return 'Replace or restyle the background with a clean studio backdrop '
            'while preserving the main subject naturally.';
      case AiOperation.ageChanger:
        return 'Apply a subtle age transformation look while keeping the person recognizable.';
      case AiOperation.artStyles:
        return 'Convert this photo into an artistic painted style while keeping composition.';
      case AiOperation.filters:
        return 'Apply a beautiful cinematic filter look with natural color grading.';
      case AiOperation.stickersText:
      case AiOperation.collage:
      case AiOperation.crop:
      case AiOperation.rotate:
      case AiOperation.compress:
      case AiOperation.formatConvert:
        return 'Enhance this photograph while keeping subjects and composition unchanged.';
    }
  }

  Future<({File file, int width, int height})> _prepareUpload(File source) async {
    final raw = await source.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw AiException(AppStrings.invalidImage, code: 'decode');
    }

    var image = decoded;
    const maxSide = 1536;
    if (image.width > maxSide || image.height > maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxSide : null,
        height: image.height > image.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }

    var quality = 90;
    var encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    while (encoded.lengthInBytes > 3 * 1024 * 1024 && quality > 55) {
      quality -= 10;
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'openai_in_${_uuid.v4()}.jpg'));
    await file.writeAsBytes(encoded, flush: true);
    return (file: file, width: image.width, height: image.height);
  }

  String _outputSizeFor(int width, int height) {
    final ratio = width / height;
    if (ratio > 1.2) return '1536x1024';
    if (ratio < 0.83) return '1024x1536';
    return '1024x1024';
  }

  Future<Uint8List> _extractImageBytes(Map<String, dynamic>? data) async {
    if (data == null) {
      throw AiException(AppStrings.processingFailed, code: 'empty');
    }
    final list = data['data'];
    if (list is! List || list.isEmpty) {
      throw AiException(AppStrings.processingFailed, code: 'no_data');
    }
    final first = list.first;
    if (first is! Map) {
      throw AiException(AppStrings.processingFailed, code: 'bad_data');
    }

    final b64 = first['b64_json'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      return Uint8List.fromList(base64Decode(b64));
    }

    final url = first['url'] as String?;
    if (url != null && url.isNotEmpty) {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? []);
    }

    throw AiException(AppStrings.processingFailed, code: 'no_image');
  }

  Future<File> _writeTemp(Uint8List bytes, String prefix) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${prefix}_${_uuid.v4()}.jpg'));
    // Ensure JPEG output even if PNG bytes returned.
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      await file.writeAsBytes(
        img.encodeJpg(decoded, quality: 92),
        flush: true,
      );
    } else {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  Future<File> _upscaleLocally(
    File source, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return source;

    final maxDim = AppConfig.maxImageDimension;
    var tw = targetWidth.clamp(1, maxDim);
    var th = targetHeight.clamp(1, maxDim);

    final resized = img.copyResize(
      decoded,
      width: tw,
      height: th,
      interpolation: img.Interpolation.cubic,
    );

    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'upscaled_${_uuid.v4()}.jpg'));
    await out.writeAsBytes(img.encodeJpg(resized, quality: 93), flush: true);
    return out;
  }

  AiException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String? apiMessage;
    if (body is Map && body['error'] is Map) {
      apiMessage = (body['error'] as Map)['message']?.toString();
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return AiException(AppStrings.offlineRequired, code: 'offline', cause: e);
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AiException(
        'The AI request timed out. Please try again.',
        code: 'timeout',
        cause: e,
      );
    }

    switch (status) {
      case 401:
        return AiException(
          'Invalid OpenAI API key. Check Settings.',
          code: '401',
          cause: e,
        );
      case 403:
        return AiException(
          'OpenAI access denied. Verify billing and image model access.',
          code: '403',
          cause: e,
        );
      case 429:
        return AiException(
          'OpenAI rate limit reached. Wait a moment and try again.',
          code: '429',
          cause: e,
        );
      case 400:
        return AiException(
          apiMessage != null && apiMessage.isNotEmpty
              ? 'Unable to process this photo. Try another image.'
              : AppStrings.invalidImage,
          code: '400',
          cause: e,
        );
      default:
        return AiException(
          AppStrings.processingFailed,
          code: '$status',
          cause: e,
        );
    }
  }
}

/// Used when no AI provider is configured — fails clearly, never fakes results.
class UnconfiguredAiService implements AiService {
  @override
  bool get requiresNetwork => false;

  Future<AiProcessingResponse> _fail() async {
    throw AiException(
      'AI is not configured. Add your OpenAI API key in Settings '
      '(or set OPENAI_API_KEY / API_BASE_URL).',
      code: 'unconfigured',
    );
  }

  @override
  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  }) =>
      _fail();

  @override
  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  }) =>
      _fail();

  @override
  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options = const {},
  }) =>
      _fail();

  @override
  Future<AiProcessingResponse> colorizePhoto({required File image}) => _fail();

  @override
  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  }) =>
      _fail();

  @override
  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  }) =>
      _fail();

  @override
  Future<AiProcessingResponse> getProcessingStatus(String jobId) => _fail();

  @override
  Future<AiProcessingResponse> process(AiProcessingRequest request) => _fail();
}
