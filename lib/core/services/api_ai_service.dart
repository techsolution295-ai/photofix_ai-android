import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/ai_models.dart';
import '../config/app_config.dart';
import '../constants/app_strings.dart';
import 'ai_service.dart';

class ApiAiService implements AiService {
  ApiAiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 120),
                headers: const {
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;

  @override
  bool get requiresNetwork => true;

  @override
  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  }) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.enhance,
        strength: strength,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  }) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.upscale,
        upscaleFactor: factor,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options = const {},
  }) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.restore,
        options: options,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> colorizePhoto({required File image}) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.colorize,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  }) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.denoise,
        strength: strength,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  }) {
    return process(
      AiProcessingRequest(
        imagePath: image.path,
        operation: AiOperation.sharpen,
        strength: strength,
      ),
    );
  }

  @override
  Future<AiProcessingResponse> process(AiProcessingRequest request) async {
    if (!AppConfig.hasApiConfigured) {
      throw AiException(
        'AI API is not configured. Set API_BASE_URL via --dart-define.',
        code: 'config',
      );
    }

    try {
      final file = File(request.imagePath);
      if (!await file.exists()) {
        throw AiException(AppStrings.invalidImage, code: 'invalid_image');
      }

      final form = FormData.fromMap({
        ...request.toFields(),
        'image': await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/process',
        data: form,
      );

      final parsed = AiProcessingResponse.fromJson(response.data ?? {});
      if (parsed.jobId != null && !parsed.isComplete) {
        return _pollUntilComplete(parsed.jobId!);
      }
      if (!parsed.success || (!parsed.isComplete && parsed.jobId == null)) {
        throw AiException(AppStrings.processingFailed, code: 'processing');
      }
      return parsed;
    } on AiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw AiException(AppStrings.processingFailed, cause: e);
    }
  }

  @override
  Future<AiProcessingResponse> getProcessingStatus(String jobId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/process/$jobId',
      );
      return AiProcessingResponse.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<AiProcessingResponse> _pollUntilComplete(String jobId) async {
    const maxAttempts = 60;
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final status = await getProcessingStatus(jobId);
      if (status.status == AiJobStatus.completed) {
        if (status.imageUrl == null) {
          throw AiException(AppStrings.processingFailed, code: 'no_image');
        }
        return status;
      }
      if (status.status == AiJobStatus.failed) {
        throw AiException(AppStrings.processingFailed, code: 'failed');
      }
    }
    throw AiException(AppStrings.processingFailed, code: 'timeout');
  }

  AiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AiException(
          'The request timed out. Please try again.',
          code: 'timeout',
          cause: e,
        );
      case DioExceptionType.connectionError:
        return AiException(
          AppStrings.offlineRequired,
          code: 'offline',
          cause: e,
        );
      default:
        break;
    }

    final code = e.response?.statusCode;
    switch (code) {
      case 400:
        return AiException(AppStrings.invalidImage, code: '400', cause: e);
      case 401:
      case 403:
        return AiException(
          'You are not authorized to use this feature.',
          code: '$code',
          cause: e,
        );
      case 404:
        return AiException(
          'Processing service was not found.',
          code: '404',
          cause: e,
        );
      case 429:
        return AiException(
          'Too many requests. Please wait a moment and try again.',
          code: '429',
          cause: e,
        );
      case 500:
      case 502:
      case 503:
        return AiException(
          'The AI service is temporarily unavailable. Please try again.',
          code: '$code',
          cause: e,
        );
      default:
        return AiException(AppStrings.processingFailed, code: '$code', cause: e);
    }
  }
}
