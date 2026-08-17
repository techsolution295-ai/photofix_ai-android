// Basic widget smoke test — app boots with mocked prefs via main DI is
// integration-heavy; keep a lightweight compile smoke here.
import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/theme/app_theme.dart';

void main() {
  test('themes build without throwing', () {
    expect(AppTheme.light().useMaterial3, isTrue);
    expect(AppTheme.dark().useMaterial3, isTrue);
  });
}
