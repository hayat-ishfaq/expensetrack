import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    setState(() {
      _nameError = Validators.name(name);
      _emailError = Validators.email(email);
      _passwordError = Validators.password(password);
      _confirmError = Validators.confirmPassword(
        _confirmController.text,
        password,
      );
    });
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }

    ref
        .read(authActionsProvider.notifier)
        .signUp(name: name, email: email, password: password);
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
      title: 'Create your account',
      subtitle: 'A free ${AppConstants.appName} account, ready in seconds.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(Routes.login),
          child: const Text('Already have an account? Sign in'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Full name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) {
                setState(() {
                  _nameError = Validators.name(_nameController.text);
                });
              }
            },
          ),
          const SizedBox(height: 16),
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
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmController,
            label: 'Confirm password',
            errorText: _confirmError,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 28),
          LoadingButton(
            label: 'Create account',
            isLoading: submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}