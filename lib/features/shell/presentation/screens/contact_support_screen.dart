import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: AppConstants.supportEmail),
    );
    if (context.mounted) {
      showAppSnack(context, 'Email copied.');
    }
  }

  Future<void> _openMail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': '${AppConstants.appName} support',
      },
    );
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      await _copyEmail(context);
      if (context.mounted) {
        showAppSnack(
          context,
          'No email app found. Address copied instead.',
        );
      }
    }
  }

  Future<void> _openGithub(BuildContext context) async {
    final uri = Uri.parse(AppConstants.supportGithubUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showAppSnack(context, 'Could not open the browser.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Questions, bugs, or a stuck invite code — send a note and we will get back to you.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          CoSpendCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: const TintedIcon(
                    icon: Icons.mail_outline_rounded,
                    color: CoSpendColors.jadeGreen,
                  ),
                  title: const Text('Email'),
                  subtitle: const Text(AppConstants.supportEmail),
                  trailing: IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copyEmail(context),
                  ),
                  onTap: () => _openMail(context),
                ),
                ListTile(
                  leading: const TintedIcon(
                    icon: Icons.bug_report_outlined,
                    color: CoSpendColors.prussianBlue,
                  ),
                  title: const Text('GitHub issues'),
                  subtitle: const Text('Report a bug or request a feature'),
                  onTap: () => _openGithub(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _openMail(context),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Open email app'),
            ),
          ),
        ],
      ),
    );
  }
}
