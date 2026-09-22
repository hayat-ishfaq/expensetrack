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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text;
    setState(() {
      _emailError = Validators.email(email);
    });
    if (_emailError != null) return;
    ref.read(authActionsProvider.notifier).resetPassword(email: email);
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
      } else if ((previous?.isLoading ?? false) &&
          !next.isLoading &&
          !next.hasError) {
        showAppSnack(
          context,
          'Reset link sent — check your inbox.',
        );
        context.go(Routes.login);
      }
    });

    final submitting = ref.watch(authActionsProvider).isLoading;

    return AuthScaffold(
      title: 'Reset your password',
      subtitle: "Enter the email you signed up with and we'll send you a "
          'reset link.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(Routes.login),
          child: const Text('Back to sign in'),
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
            textInputAction: TextInputAction.done,
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
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 28),
          LoadingButton(
            label: 'Send reset link',
            isLoading: submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}