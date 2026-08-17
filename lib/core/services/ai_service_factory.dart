import '../config/app_config.dart';
import 'ai_service.dart';
import 'api_ai_service.dart';
import 'local_ai_service.dart';
import 'openai_ai_service.dart';
import 'openai_key_store.dart';

class AiServiceFactory {
  /// Default: on-device processing (no key needed).
  /// If OpenAI key is set → cloud OpenAI.
  /// Else if API_BASE_URL set → custom backend.
  static AiService create(OpenAiKeyStore keys) {
    AppConfig.assertProductionReady();

    final local = LocalAiService();

    return HybridAiService(
      local: local,
      hasCloudKey: () => keys.hasKey || AppConfig.hasApiConfigured,
      cloudFactory: () {
        if (keys.hasKey) return OpenAiAiService(keys);
        if (AppConfig.hasApiConfigured) return ApiAiService();
        return local;
      },
    );
  }
}
