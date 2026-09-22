import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';

/// Shown right after sign-up: create a new flat or join an existing one.
class HouseholdSetupScreen extends StatelessWidget {
  const HouseholdSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set up your flat',
      subtitle: 'Create a new flat or join your roommates with the invite '
          'code they shared with you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.go(Routes.createFlat),
              icon: const Icon(Icons.add_home_rounded),
              label: const Text('Create a flat'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.go(Routes.joinFlat),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join with an invite code'),
            ),
          ),
        ],
      ),
    );
  }
}