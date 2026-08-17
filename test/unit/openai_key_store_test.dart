import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/services/openai_key_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenAiKeyStore', () {
    test('runtime key is stored and masked', () async {
      SharedPreferences.setMockInitialValues({});
      final store = OpenAiKeyStore(await SharedPreferences.getInstance());
      expect(store.hasKey, isFalse);

      await store.setRuntimeKey('sk-abcdefghijklmnopqrstuvwxyz');
      expect(store.hasKey, isTrue);
      expect(store.effectiveKey, startsWith('sk-'));
      expect(store.maskedKey, contains('••••'));

      await store.setRuntimeKey(null);
      expect(store.hasKey, isFalse);
    });
  });
}
