import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/responsive_center.dart';

/// Branded entry screen shown to signed-out users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<({IconData icon, String title, String subtitle})>
      _features = [
    (
      icon: Icons.groups_rounded,
      title: 'Built for flatmates',
      subtitle:
          'Create one flat, invite your roommates and share every expense fairly.',
    ),
    (
      icon: Icons.savings_rounded,
      title: 'Know where you stand',
      subtitle:
          'See exactly who owes whom, with settlement suggestions in one tap.',
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Spending you understand',
      subtitle:
          'Monthly trends, category breakdowns and a budget that keeps you honest.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 24,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                Text(
                  'Shared expenses,\nsimplified.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Create a flat, invite your roommates, and let '
                  '${AppConstants.appName} keep track of who owes what — '
                  'down to the last rupee.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 40),
                ..._features.map(
                  (feature) => _FeatureTile(
                    icon: feature.icon,
                    title: feature.title,
                    subtitle: feature.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.go(Routes.signup),
                  child: const Text('Get started'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(Routes.login),
                  child: const Text('I already have an account'),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    AppConstants.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}