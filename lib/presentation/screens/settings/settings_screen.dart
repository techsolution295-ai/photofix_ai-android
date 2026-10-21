import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/pro_purchase_service.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openSupport() => _launchUrl(AppConfig.supportEmailUri);
  void _openPrivacy() => _launchUrl(AppConfig.privacyPolicyUrl);
  void _openTerms() => _launchUrl(AppConfig.termsUrl);

  Future<void> _restore(BuildContext context) async {
    await context.read<ProPurchaseService>().restore();
    if (!context.mounted) return;
    final isPremium = context.read<SettingsProvider>().isPremium;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPremium
              ? 'Pro access restored.'
              : 'No active subscription was found.',
        ),
      ),
    );
  }

  Future<void> _rateUs() async {
    final market = Uri.parse('market://details?id=${AppConfig.packageName}');
    final web = Uri.parse(
      'https://play.google.com/store/apps/details?id=${AppConfig.packageName}',
    );
    try {
      if (await canLaunchUrl(market)) {
        final opened = await launchUrl(
          market,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      }
    } catch (_) {}
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            const SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _ProBanner(),
            const SizedBox(height: 20),
            _SettingsTile(
              icon: Icons.restore_rounded,
              iconBg: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF7C3AED),
              title: 'Restore Purchases',
              onTap: () => _restore(context),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              iconBg: const Color(0xFFEEE8FF),
              iconColor: const Color(0xFF6C4CF1),
              title: 'Privacy Policy',
              onTap: _openPrivacy,
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.description_outlined,
              iconBg: const Color(0xFFE8F0FF),
              iconColor: const Color(0xFF3B82F6),
              title: 'Terms and Conditions',
              onTap: _openTerms,
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.support_agent_rounded,
              iconBg: const Color(0xFFE6FBF8),
              iconColor: const Color(0xFF14B8A6),
              title: 'Support',
              onTap: _openSupport,
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.star_rounded,
              iconBg: const Color(0xFFFFF6E0),
              iconColor: const Color(0xFFF5B942),
              title: 'Rate Us',
              onTap: _rateUs,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SettingsProvider>().isPremium;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: isPro
            ? null
            : () => Navigator.of(context).pushNamed(RouteNames.premium),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4B1FD6),
                Color(0xFF5B3DF5),
                Color(0xFF4568FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3DF5).withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -18,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: -28,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? "YOU'RE PRO" : 'GO PRO',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro ? 'Ads are off' : 'Unlock every photo tool',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro
                        ? 'Your plan is active on this device.'
                        : 'Remove ads and keep every photo tool.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA0B4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
