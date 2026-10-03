import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailErr = Validators.email(email);
    final passErr = Validators.password(password);

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
      _formError = null;
    });

    if (emailErr != null || passErr != null) {
      if (emailErr != null && passErr != null) {
        setState(() {
          _formError = 'Please fill in both email and password.';
        });
      }
      return;
    }

    ref.read(authActionsProvider.notifier).signIn(
          email: email,
          password: password,
        );
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
        ref.invalidate(sessionProvider);
      }
    });

    final submitting = ref.watch(authActionsProvider).isLoading;

    // Provide contextual action in error banner if appropriate
    String? bannerActionLabel;
    VoidCallback? bannerAction;
    if (_formError != null) {
      final lower = _formError!.toLowerCase();
      if (lower.contains('no account found') || lower.contains('not found')) {
        bannerActionLabel = 'Create an account';
        bannerAction = () => context.go(Routes.signup);
      } else if (lower.contains('incorrect') || lower.contains('password')) {
        bannerActionLabel = 'Forgot password?';
        bannerAction = () => context.go(Routes.forgotPassword);
      }
    }

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to see your flat’s expenses, balances and '
          'settle-up suggestions.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(Routes.signup),
          child: const Text('New here? Create an account'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
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
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            errorText: _passwordError,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(Routes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_formError != null)
            AuthErrorBanner(
              message: _formError!,
              actionLabel: bannerActionLabel,
              onAction: bannerAction,
              onDismiss: () => setState(() => _formError = null),
            ),
          const SizedBox(height: 4),
          LoadingButton(
            label: 'Sign in',
            isLoading: submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}