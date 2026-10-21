import 'package:flutter/material.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';

/// Opens the paywall. No interstitial.
class ProChip extends StatelessWidget {
  const ProChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(RouteNames.premium),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: AppColors.primaryGradient,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/pro_crown.png',
                width: 15,
                height: 15,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 4),
              const Text(
                'PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
