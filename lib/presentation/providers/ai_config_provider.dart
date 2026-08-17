import 'package:flutter/material.dart';

import '../../core/services/openai_key_store.dart';

class AiConfigProvider extends ChangeNotifier {
  AiConfigProvider(this._keys);

  final OpenAiKeyStore _keys;

  bool get hasKey => _keys.hasKey;
  String get maskedKey => _keys.maskedKey;
  OpenAiKeyStore get store => _keys;

  Future<void> saveKey(String? key) async {
    await _keys.setRuntimeKey(key);
    notifyListeners();
  }

  Future<void> clearKey() async {
    await _keys.setRuntimeKey(null);
    notifyListeners();
  }
}
