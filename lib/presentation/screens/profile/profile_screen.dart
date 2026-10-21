import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  Future<void> _contact() async {
    await launchUrl(
      Uri.parse(AppConfig.supportEmailUri),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            title: const Text('PhotoFix AI'),
            subtitle: const Text('All AI tools are free'),
          ),
          const Divider(),
          _section('App'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text(AppStrings.history),
            onTap: () => Navigator.pushNamed(context, RouteNames.history),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text(AppStrings.settings),
            onTap: () => Navigator.pushNamed(context, RouteNames.settings),
          ),
          _section('Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.helpFaq),
            onTap: () => Navigator.pushNamed(context, RouteNames.help),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text(AppStrings.contactSupport),
            onTap: _contact,
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text(AppStrings.rateApp),
            onTap: () async {
              final market = Uri.parse(
                'market://details?id=${AppConfig.packageName}',
              );
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
            },
          ),
          _section('Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacyPolicy),
            onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.termsOfUse),
            onTap: () => _openUrl(AppConfig.termsUrl),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Version $_version',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
