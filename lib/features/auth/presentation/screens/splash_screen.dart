import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/session_provider.dart';

/// Root splash screen.
///
/// The session provider resolves auth + household membership; the router
/// redirects away automatically once it settles. If Firebase cannot be
/// reached (or isn't configured yet), a clear error with retry is shown
/// instead of an infinite spinner.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (session.hasError && !session.isLoading) {
      final error = session.error!;
      final message = error is AppException
          ? error.message
          : FirebaseErrorMapper.messageFor(error);
      return Scaffold(
        body: SafeArea(
          child: ErrorView(
            title: "Can't connect to FlatSplit",
            message: message,
            onRetry: () => ref.invalidate(sessionProvider),
          ),
        ),
      );
    }

    return Scaffold(body: SafeArea(child: const _SplashBranding()));
  }
}

class _SplashBranding extends StatelessWidget {
  const _SplashBranding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 38,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}