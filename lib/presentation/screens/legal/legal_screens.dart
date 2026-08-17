import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common_widgets.dart';

class LegalPageScreen extends StatelessWidget {
  const LegalPageScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final configured = url.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: configured
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Open the full $title in your browser.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Open $title',
                    onPressed: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title URL is not configured.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Before production release, set the URL via --dart-define '
                    '(PRIVACY_POLICY_URL / TERMS_URL) or update AppConfig.\n\n'
                    'This placeholder intentionally avoids inventing legal claims.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
      ),
    );
  }
}

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        q: 'Is PhotoFix AI free?',
        a: 'Yes. All AI tools are free. Processing runs on your device by default — no API key required.',
      ),
      (
        q: 'Do I need internet?',
        a: 'On-device mode works offline. Internet is only needed if you optionally enable OpenAI cloud processing in Settings.',
      ),
      (
        q: 'What is the OpenAI key for?',
        a: 'Optional. The app already enhances photos on your phone. Add an OpenAI key only if you want cloud AI results.',
      ),
      (
        q: 'Where are my photos saved?',
        a: 'Use Save to Gallery on the result screen. History keeps local copies of recent results on this device.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.helpFaq)),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, i) {
          final item = faqs[i];
          return ExpansionTile(
            title: Text(item.q),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(item.a),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScreen(
      title: AppStrings.privacyPolicy,
      url: AppConfig.privacyPolicyUrl,
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScreen(
      title: AppStrings.termsOfUse,
      url: AppConfig.termsUrl,
    );
  }
}
