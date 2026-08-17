import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';
import '../config/app_config.dart';

class EntitlementService {
  EntitlementService(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'entitlement_type';
  static const _productKey = 'entitlement_product_id';

  EntitlementType get current {
    return EntitlementTypeX.fromStorage(_prefs.getString(_key));
  }

  bool isProUser() => current.isPro;

  String? get activeProductId => _prefs.getString(_productKey);

  Future<void> setEntitlement(EntitlementType type, {String? productId}) async {
    await _prefs.setString(_key, type.storageKey);
    if (productId != null) {
      await _prefs.setString(_productKey, productId);
    } else if (type == EntitlementType.free) {
      await _prefs.remove(_productKey);
    }
  }

  EntitlementType mapProductId(String productId) {
    if (productId == AppConfig.productLifetime) {
      return EntitlementType.lifetime;
    }
    if (productId == AppConfig.productYearly) {
      return EntitlementType.proYearly;
    }
    if (productId == AppConfig.productMonthly) {
      return EntitlementType.proMonthly;
    }
    return EntitlementType.free;
  }
}
