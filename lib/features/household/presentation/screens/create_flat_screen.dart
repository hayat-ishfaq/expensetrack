import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../providers/household_providers.dart';

class CreateFlatScreen extends ConsumerStatefulWidget {
  const CreateFlatScreen({super.key});

  @override
  ConsumerState<CreateFlatScreen> createState() => _CreateFlatScreenState();
}

class _CreateFlatScreenState extends ConsumerState<CreateFlatScreen> {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text;
    setState(() {
      _nameError = Validators.flatName(name);
    });
    if (_nameError != null) return;
    ref.read(householdActionsProvider.notifier).create(name: name);
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
        showAppSnack(context, 'Flat created successfully!');
        context.go(Routes.home);
      }
    });

    final submitting = ref.watch(householdActionsProvider).isLoading;

    return AuthScaffold(
      showBack: true,
      title: 'Create a flat',
      subtitle: 'Give your shared home a name — something like '
          '"Air University Flat".',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Flat name',
              prefixIcon: const Icon(Icons.home_outlined),
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) {
                setState(() {
                  _nameError = Validators.flatName(_nameController.text);
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 28),
          LoadingButton(
            label: 'Create flat',
            isLoading: submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Text(
            "You'll become the owner and can share an invite code with "
            'your roommates right away.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}