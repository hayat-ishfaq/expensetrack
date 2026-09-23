import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../shared/widgets/responsive_center.dart';

/// Shared layout for the auth screens: brand header, headline and a scrollable
/// form area that stays readable on small screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: CoSpendSpacing.xl,
              vertical: CoSpendSpacing.xl,
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
                        width: 40,
                        height: 40,
                        errorBuilder: (_, _, _) => Container(
                          width: 40,
                          height: 40,
                          color: CoSpendColors.prussianBlue,
                          child: const Icon(
                            Icons.wallet_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: CoSpendSpacing.sm),
                    Text(
                      AppConstants.appName,
                      style: CoSpendTypography.ofTitle(context).copyWith(
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CoSpendSpacing.xxxl),
                Text(
                  title,
                  style: CoSpendTypography.ofHeadline(context).copyWith(
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.xs),
                Text(
                  subtitle,
                  style: CoSpendTypography.ofBody(context).copyWith(
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.xxl),
                child,
                if (footer != null) ...[
                  const SizedBox(height: CoSpendSpacing.lg),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
