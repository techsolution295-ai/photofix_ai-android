import 'package:flutter/material.dart';

import '../../core/services/ad_service.dart';

/// Opens a photo tool after an interstitial. Pro members skip the ad.
Future<void> openTool(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  return AdService.instance.showSelectInterstitialThen(() async {
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed(route, arguments: arguments);
  });
}
