import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/motion.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CoSpendColors.jadeGreen.withValues(alpha: isDark ? 0.12 : 0.14),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ResponsiveCenter(
              maxWidth: 520,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      child: Row(
                        children: [
                          Hero(
                            tag: 'app-logo',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 44,
                                height: 44,
                                errorBuilder: (_, _, _) => Container(
                                  width: 44,
                                  height: 44,
                                  color: scheme.primary,
                                  child: const Icon(
                                    Icons.wallet_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppConstants.appName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Co-living budgets,\nshared simply.',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(
                        'Track shared household expenses, set category budgets, and keep flatmates in sync with ${AppConstants.appName}.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    for (var i = 0; i < _features.length; i++)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 180 + i * 70),
                        child: _FeatureTile(
                          icon: _features[i].icon,
                          title: _features[i].title,
                          subtitle: _features[i].subtitle,
                        ),
                      ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: () => context.go(Routes.signup),
                            child: const Text('Get started'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => context.go(Routes.login),
                            child: const Text('I already have an account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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
        ],
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIcon(icon: icon, color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
