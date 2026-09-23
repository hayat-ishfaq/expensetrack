import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../providers/household_providers.dart';

class JoinFlatScreen extends ConsumerStatefulWidget {
  const JoinFlatScreen({super.key});

  @override
  ConsumerState<JoinFlatScreen> createState() => _JoinFlatScreenState();
}

class _JoinFlatScreenState extends ConsumerState<JoinFlatScreen> {
  final _codeController = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _codeController.text;
    final code = Validators.normalizeInviteCode(raw);
    setState(() {
      _codeError = Validators.inviteCode(raw);
    });
    if (_codeError != null) return;
    ref.read(householdActionsProvider.notifier).join(inviteCode: code);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(householdActionsProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error!;
        showAppSnack(
          context,
          error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          error: true,
        );
      } else if (!next.isLoading &&
          !next.hasError &&
          previous?.isLoading == true) {
        showAppSnack(context, 'Successfully joined flat!');
        context.go(Routes.home);
      }
    });

    final submitting = ref.watch(householdActionsProvider).isLoading;

    return AuthScaffold(
      title: 'Join a flat',
      subtitle: 'Enter the invite code your roommate shared. It looks like '
          'FLAT-7K29.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeController,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Invite code',
              hintText: 'FLAT-ABCD',
              prefixIcon: const Icon(Icons.key_rounded),
              errorText: _codeError,
            ),
            onChanged: (_) {
              if (_codeError != null) {
                setState(() {
                  _codeError = Validators.inviteCode(_codeController.text);
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: CoSpendSpacing.xl),
          LoadingButton(
            label: 'Join flat',
            isLoading: submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: CoSpendSpacing.md),
          Text(
            'The code is case-insensitive — "flat-7k29" works the same as '
            'FLAT-7K29.',
            style: CoSpendTypography.ofBodySmall(context).copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}