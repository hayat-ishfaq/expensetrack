import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _formError;
  bool _isEmailSent = false;
  String _submittedEmail = '';
  Timer? _cooldownTimer;
  int _countdown = 30;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _countdown = 30;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _submit() {
    final email = _emailController.text.trim();
    final err = Validators.email(email);
    setState(() {
      _emailError = err;
      _formError = null;
    });
    if (err != null) return;
    ref.read(authActionsProvider.notifier).resetPassword(email: email);
  }

  void _resend() {
    if (_countdown > 0) return;
    ref.read(authActionsProvider.notifier).resetPassword(email: _submittedEmail);
  }

  Future<void> _openEmailApp() async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          showAppSnack(
            context,
            'Could not launch email app. Please check your inbox manually.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'Could not launch email app. Please check your inbox manually.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authActionsProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error!;
        final message = error is AppException
            ? error.message
            : FirebaseErrorMapper.messageFor(error);

        setState(() {
          _formError = message;
        });

        showAppSnack(
          context,
          message,
          error: true,
        );
      } else if ((previous?.isLoading ?? false) &&
          !next.isLoading &&
          !next.hasError) {
        setState(() {
          _formError = null;
        });
        if (!_isEmailSent) {
          setState(() {
            _isEmailSent = true;
            _submittedEmail = _emailController.text.trim();
          });
        } else {
          showAppSnack(
            context,
            'Reset link resent — check your inbox.',
          );
        }
        _startCooldown();
      }
    });

    final submitting = ref.watch(authActionsProvider).isLoading;

    if (_isEmailSent) {
      return _buildSuccessState(context, submitting);
    }

    return _buildInputState(context, submitting);
  }

  Widget _buildInputState(BuildContext context, bool submitting) {
    final theme = Theme.of(context);

    String? bannerActionLabel;
    VoidCallback? bannerAction;
    if (_formError != null) {
      final lower = _formError!.toLowerCase();
      if (lower.contains('no account found') || lower.contains('not found')) {
        bannerActionLabel = 'Create an account';
        bannerAction = () => context.go(Routes.signup);
      }
    }

    return AuthScaffold(
      showBack: true,
      title: 'Reset password',
      subtitle: "Enter the email you signed up with and we'll send you a "
          'link to reset your password.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Remember your password? ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'alex@example.com',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null || _formError != null) {
                setState(() {
                  _emailError = Validators.email(_emailController.text.trim());
                  _formError = null;
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          if (_formError != null)
            AuthErrorBanner(
              message: _formError!,
              actionLabel: bannerActionLabel,
              onAction: bannerAction,
              onDismiss: () => setState(() => _formError = null),
            ),
          LoadingButton(
            label: 'Send reset link',
            isLoading: submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, bool submitting) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      showBack: true,
      title: 'Check your inbox',
      subtitle:
          'We have sent password reset instructions to your registered email address.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(Routes.login),
          child: const Text('Back to sign in'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: CoSpendColors.jadeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: CoSpendColors.jadeGreenDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sent to',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _submittedEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openEmailApp,
            icon: const Icon(Icons.mail_outline_rounded, size: 20),
            label: const Text('Open email app'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: (_countdown > 0 || submitting) ? null : _resend,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _countdown > 0
                        ? 'Resend link in ${_countdown}s'
                        : 'Resend reset link',
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _cooldownTimer?.cancel();
              setState(() {
                _isEmailSent = false;
                _countdown = 30;
              });
            },
            child: const Text('Try a different email'),
          ),
        ],
      ),
    );
  }
}