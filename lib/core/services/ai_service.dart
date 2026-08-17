import 'dart:io';

import '../../domain/models/ai_models.dart';

/// Abstract AI processing service.
abstract class AiService {
  /// When false, processing can run offline (on-device).
  bool get requiresNetwork => true;

  Future<AiProcessingResponse> enhancePhoto({
    required File image,
    required String strength,
  });

  Future<AiProcessingResponse> upscalePhoto({
    required File image,
    required int factor,
  });

  Future<AiProcessingResponse> restorePhoto({
    required File image,
    Map<String, dynamic> options,
  });

  Future<AiProcessingResponse> colorizePhoto({required File image});

  Future<AiProcessingResponse> removeNoise({
    required File image,
    required String strength,
  });

  Future<AiProcessingResponse> sharpenPhoto({
    required File image,
    required String strength,
  });

  Future<AiProcessingResponse> getProcessingStatus(String jobId);

  Future<AiProcessingResponse> process(AiProcessingRequest request);
}
