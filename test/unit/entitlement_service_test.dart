import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/services/entitlement_service.dart';
import 'package:photofix_ai/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntitlementService', () {
    late EntitlementService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = EntitlementService(await SharedPreferences.getInstance());
    });

    test('defaults to free', () {
      expect(service.current, EntitlementType.free);
      expect(service.isProUser(), isFalse);
    });

    test('lifetime unlock marks user as Pro', () async {
      await service.setEntitlement(
        EntitlementType.lifetime,
        productId: 'photofix_lifetime',
      );
      expect(service.isProUser(), isTrue);
      expect(service.current, EntitlementType.lifetime);
    });

    test('maps product ids correctly', () {
      expect(
        service.mapProductId('photofix_pro_monthly'),
        EntitlementType.proMonthly,
      );
      expect(
        service.mapProductId('photofix_pro_yearly'),
        EntitlementType.proYearly,
      );
      expect(
        service.mapProductId('photofix_lifetime'),
        EntitlementType.lifetime,
      );
      expect(service.mapProductId('unknown'), EntitlementType.free);
    });
  });
}
