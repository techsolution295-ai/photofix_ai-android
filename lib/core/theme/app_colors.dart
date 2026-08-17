import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C4CF1);
  static const Color secondary = Color(0xFF2677FF);
  static const Color background = Color(0xFFF7F8FC);
  static const Color darkText = Color(0xFF151827);
  static const Color secondaryText = Color(0xFF737789);
  static const Color premiumGold = Color(0xFFF5B942);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);

  static const Color cardLight = Colors.white;
  static const Color dividerLight = Color(0xFFE8EAF2);

  static const Color backgroundDark = Color(0xFF0F111A);
  static const Color cardDark = Color(0xFF1A1D2B);
  static const Color darkTextOnDark = Color(0xFFF2F3F8);
  static const Color secondaryTextDark = Color(0xFFA0A4B8);
  static const Color dividerDark = Color(0xFF2A2E40);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFF5B942), Color(0xFFE08A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
