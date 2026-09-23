import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_system.dart';
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
          CoSpendPrimaryButton(
            onPressed: () => context.go(Routes.createFlat),
            icon: Icons.add_home_rounded,
            label: 'Create a flat',
          ),
          const SizedBox(height: CoSpendSpacing.sm),
          CoSpendSecondaryButton(
            onPressed: () => context.go(Routes.joinFlat),
            icon: Icons.group_add_outlined,
            label: 'Join with an invite code',
          ),
        ],
      ),
    );
  }
}