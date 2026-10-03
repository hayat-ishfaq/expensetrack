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

    setState(() {
      _emailError = Validators.email(email);
      _passwordError = Validators.password(password);
      _formError = null;
    });

    if (_emailError != null || _passwordError != null) return;

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
        // Sign-in succeeded. Ensure session provider refreshes state immediately.
        setState(() {
          _formError = null;
        });
        ref.invalidate(sessionProvider);
      }
    });

    final submitting = ref.watch(authActionsProvider).isLoading;

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
          if (_formError != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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