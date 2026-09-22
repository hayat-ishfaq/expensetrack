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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text;
    final password = _passwordController.text;
    setState(() {
      _emailError = Validators.email(email);
      _passwordError = Validators.password(password);
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
        showAppSnack(
          context,
          error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          error: true,
        );
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
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null) {
                setState(() {
                  _emailError = Validators.email(_emailController.text);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            errorText: _passwordError,
            autofillHints: const [AutofillHints.password],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(Routes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
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