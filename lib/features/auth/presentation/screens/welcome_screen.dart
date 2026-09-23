import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: CoSpendSpacing.xl,
              vertical: CoSpendSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: CoSpendRadii.mediumRadius,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 44,
                        height: 44,
                        errorBuilder: (_, _, _) => Container(
                          width: 44,
                          height: 44,
                          color: CoSpendColors.prussianBlue,
                          child: const Icon(
                            Icons.wallet_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: CoSpendSpacing.sm),
                    Text(
                      AppConstants.appName,
                      style: CoSpendTypography.ofHeadline(context).copyWith(
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CoSpendSpacing.huge),
                Text(
                  'Co-living budgets,\nshared simply.',
                  style: CoSpendTypography.ofDisplay(context).copyWith(
                    height: 1.15,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.sm),
                Text(
                  'Track shared household expenses, set category budgets, and keep flatmates in sync with ${AppConstants.appName}.',
                  style: CoSpendTypography.ofBody(context).copyWith(
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.xxxl),
                ..._features.map(
                  (feature) => _FeatureTile(
                    icon: feature.icon,
                    title: feature.title,
                    subtitle: feature.subtitle,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.sm),
                CoSpendPrimaryButton(
                  label: 'Get started',
                  onPressed: () => context.go(Routes.signup),
                ),
                const SizedBox(height: CoSpendSpacing.sm),
                CoSpendSecondaryButton(
                  label: 'I already have an account',
                  onPressed: () => context.go(Routes.login),
                ),
                const SizedBox(height: CoSpendSpacing.huge),
                Center(
                  child: Text(
                    AppConstants.tagline,
                    style: CoSpendTypography.ofBodySmall(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: CoSpendSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIcon(
            icon: icon,
            color: CoSpendColors.jadeGreen,
            size: 20,
            containerSize: 40,
          ),
          const SizedBox(width: CoSpendSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CoSpendTypography.ofTitle(context).copyWith(
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: CoSpendTypography.ofBody(context).copyWith(
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
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