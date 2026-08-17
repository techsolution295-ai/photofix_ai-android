enum AiOperation {
  enhance,
  upscale,
  restore,
  colorize,
  denoise,
  sharpen,
  cartoon,
  portrait,
  backgroundChanger,
  stickersText,
  ageChanger,
  artStyles,
  filters,
  collage,
  crop,
  rotate,
  compress,
  formatConvert;

  String get apiValue => name;

  String get displayName {
    switch (this) {
      case AiOperation.enhance:
        return 'AI Enhance';
      case AiOperation.upscale:
        return 'AI Upscale';
      case AiOperation.restore:
        return 'Restore Photo';
      case AiOperation.colorize:
        return 'Colorize';
      case AiOperation.denoise:
        return 'Remove Noise';
      case AiOperation.sharpen:
        return 'Sharpen Photo';
      case AiOperation.cartoon:
        return 'AI Cartoon';
      case AiOperation.portrait:
        return 'AI Portrait';
      case AiOperation.backgroundChanger:
        return 'Background Changer';
      case AiOperation.stickersText:
        return 'Stickers & Text';
      case AiOperation.ageChanger:
        return 'Age Changer';
      case AiOperation.artStyles:
        return 'Art Styles';
      case AiOperation.filters:
        return 'Filters';
      case AiOperation.collage:
        return 'Collage Maker';
      case AiOperation.crop:
        return 'Crop';
      case AiOperation.rotate:
        return 'Rotate';
      case AiOperation.compress:
        return 'Compress';
      case AiOperation.formatConvert:
        return 'Format Convert';
    }
  }

  bool get isCreativeStyle => switch (this) {
        AiOperation.cartoon ||
        AiOperation.portrait ||
        AiOperation.backgroundChanger ||
        AiOperation.ageChanger ||
        AiOperation.artStyles ||
        AiOperation.filters =>
          true,
        _ => false,
      };

  static AiOperation fromString(String value) {
    return AiOperation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiOperation.enhance,
    );
  }
}

enum EnhanceStrength { auto, light, standard, strong }

enum DenoiseStrength { low, medium, high }

enum SharpenStrength { low, medium, high }

enum UpscaleFactor {
  x2(2),
  x4(4);

  const UpscaleFactor(this.value);
  final int value;
}

class AiProcessingRequest {
  const AiProcessingRequest({
    required this.imagePath,
    required this.operation,
    this.strength,
    this.upscaleFactor,
    this.options = const {},
  });

  final String imagePath;
  final AiOperation operation;
  final String? strength;
  final int? upscaleFactor;
  final Map<String, dynamic> options;

  Map<String, dynamic> toFields() {
    return {
      'operation': operation.apiValue,
      if (strength != null) 'strength': strength,
      if (upscaleFactor != null) 'upscale_factor': upscaleFactor,
      ...options,
    };
  }
}

class AiProcessingResponse {
  const AiProcessingResponse({
    required this.success,
    this.jobId,
    this.imageUrl,
    this.localImagePath,
    this.error,
    this.message,
    this.progress,
    this.status = AiJobStatus.completed,
  });

  final bool success;
  final String? jobId;
  final String? imageUrl;
  final String? localImagePath;
  final String? error;
  final String? message;
  final double? progress;
  final AiJobStatus status;

  bool get isComplete =>
      status == AiJobStatus.completed &&
      (imageUrl != null || localImagePath != null);

  bool get isFailed => status == AiJobStatus.failed || !success && jobId == null;

  factory AiProcessingResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?)?.toLowerCase();
    AiJobStatus status = AiJobStatus.completed;
    if (statusStr == 'pending' || statusStr == 'queued') {
      status = AiJobStatus.pending;
    } else if (statusStr == 'processing' || statusStr == 'running') {
      status = AiJobStatus.processing;
    } else if (statusStr == 'failed' || statusStr == 'error') {
      status = AiJobStatus.failed;
    }

    return AiProcessingResponse(
      success: json['success'] as bool? ?? status != AiJobStatus.failed,
      jobId: json['job_id'] as String? ?? json['jobId'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      error: json['error'] as String?,
      message: json['message'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      status: status,
    );
  }
}

enum AiJobStatus { pending, processing, completed, failed }

class AiException implements Exception {
  AiException(this.userMessage, {this.code, this.cause});

  final String userMessage;
  final String? code;
  final Object? cause;

  @override
  String toString() => userMessage;
}
