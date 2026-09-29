import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/motion.dart';
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
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showBack)
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go(Routes.householdSetup);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (_, _, _) => Container(
                          width: 40,
                          height: 40,
                          color: scheme.primary,
                          child: const Icon(
                            Icons.wallet_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FadeSlideIn(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: child,
                ),
                if (footer != null) ...[const SizedBox(height: 20), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
