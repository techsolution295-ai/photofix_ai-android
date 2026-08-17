import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/domain/models/ai_models.dart';

void main() {
  group('AiProcessingResponse parsing', () {
    test('parses completed response', () {
      final r = AiProcessingResponse.fromJson({
        'success': true,
        'job_id': 'abc',
        'image_url': 'https://cdn.example.com/out.jpg',
        'status': 'completed',
      });
      expect(r.success, isTrue);
      expect(r.jobId, 'abc');
      expect(r.imageUrl, 'https://cdn.example.com/out.jpg');
      expect(r.isComplete, isTrue);
    });

    test('parses async pending job', () {
      final r = AiProcessingResponse.fromJson({
        'success': true,
        'jobId': 'job-1',
        'status': 'processing',
        'progress': 0.4,
      });
      expect(r.status, AiJobStatus.processing);
      expect(r.progress, 0.4);
      expect(r.isComplete, isFalse);
    });

    test('parses failed status', () {
      final r = AiProcessingResponse.fromJson({
        'success': false,
        'status': 'failed',
        'error': 'bad_image',
      });
      expect(r.status, AiJobStatus.failed);
      expect(r.isFailed, isTrue);
    });
  });

  group('AiOperation', () {
    test('fromString falls back safely', () {
      expect(AiOperation.fromString('colorize'), AiOperation.colorize);
      expect(AiOperation.fromString('nope'), AiOperation.enhance);
    });
  });
}
