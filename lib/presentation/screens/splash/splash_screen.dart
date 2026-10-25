import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/app_open_ad_service.dart';
import '../../../core/services/pro_purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _holdMs = 2600;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF7F8FC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _navigate();
  }

  Future<void> _navigate() async {
    final started = DateTime.now();
    final refresh = context.read<ProPurchaseService>().refreshFromStore();
    await Future<void>.delayed(const Duration(milliseconds: _holdMs));
    if (!mounted) return;
    try {
      await refresh.timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (!mounted) return;
    if (context.read<SettingsProvider>().isPremium) {
      Navigator.of(context).pushReplacementNamed(RouteNames.main);
      return;
    }

    final elapsed = DateTime.now().difference(started);
    final budget = const Duration(seconds: 6) - elapsed;
    final timeout = budget > const Duration(seconds: 2)
        ? const Duration(seconds: 2)
        : (budget > Duration.zero ? budget : const Duration(milliseconds: 400));
    try {
      await AppOpenAdManager.instance
          .showAdIfAvailable(loadTimeout: timeout)
          .timeout(timeout + const Duration(seconds: 1), onTimeout: () => false);
    } catch (_) {}
    if (!mounted) return;
    if (context.read<SettingsProvider>().isPremium) {
      Navigator.of(context).pushReplacementNamed(RouteNames.main);
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      RouteNames.premium,
      arguments: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ThemeBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                const _BrandMark(),
                const Spacer(flex: 3),
                const _BottomStatus(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background matching Home ambient theme ───────────────────

class _ThemeBackdrop extends StatelessWidget {
  const _ThemeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF3F0FF),
                Color(0xFFF6F8FF),
                Color(0xFFF8FAFC),
              ],
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: const _SoftBlob(
            size: 220,
            color: Color(0xFF6C4CF1),
            alpha: 0.14,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.94, 0.94),
                end: const Offset(1.08, 1.08),
                duration: 3400.ms,
                curve: Curves.easeInOut,
              )
              .moveY(begin: 0, end: 12, duration: 3400.ms),
        ),
        Positioned(
          top: 160,
          left: -80,
          child: const _SoftBlob(
            size: 200,
            color: Color(0xFF2677FF),
            alpha: 0.11,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(0.92, 0.92),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: 90,
          right: -40,
          child: const _SoftBlob(
            size: 170,
            color: Color(0xFF0D9488),
            alpha: 0.08,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(begin: 0, end: -16, duration: 3600.ms)
              .fade(begin: 0.7, end: 1, duration: 3600.ms),
        ),
      ],
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

// ─── Brand ────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Soft purple halo behind logo
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.12, 1.12),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .fade(begin: 0.55, end: 1, duration: 2000.ms),
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/splash_icon.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 550.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.78, 0.78),
                  end: const Offset(1, 1),
                  duration: 750.ms,
                  curve: Curves.easeOutBack,
                )
                .shimmer(
                  delay: 900.ms,
                  duration: 1100.ms,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        )
            .animate()
            .fadeIn(delay: 220.ms, duration: 500.ms)
            .slideY(
              begin: 0.28,
              end: 0,
              delay: 220.ms,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 10),
        Text(
          AppStrings.tagline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF737789),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
        )
            .animate()
            .fadeIn(delay: 420.ms, duration: 500.ms)
            .slideY(
              begin: 0.35,
              end: 0,
              delay: 420.ms,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 22),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(
              icon: Icons.auto_awesome_rounded,
              label: 'Enhance',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.photo_filter_rounded,
              label: 'Restore',
              color: AppColors.secondary,
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.hd_rounded,
              label: 'Upscale',
              color: const Color(0xFF0D9488),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 680.ms, duration: 480.ms)
            .slideY(
              begin: 0.25,
              end: 0,
              delay: 680.ms,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEEF0F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1A1D2E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom loader ────────────────────────────────────────────

class _BottomStatus extends StatelessWidget {
  const _BottomStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 132,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              minHeight: 3.5,
              backgroundColor: Color(0xFFE8EAF2),
              color: AppColors.primary,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 850.ms, duration: 420.ms)
            .slideY(
              begin: 0.35,
              end: 0,
              delay: 850.ms,
              duration: 480.ms,
            ),
        const SizedBox(height: 14),
        const Text(
          'Loading PhotoFix AI…',
          style: TextStyle(
            color: Color(0xFF9AA0B4),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 1000.ms, duration: 420.ms),
      ],
    );
  }
}
