import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';

/// Settings tab: appearance, flat management, monthly budget, and account.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});


  Future<void> _renameFlat(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename Flat'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Flat name',
              hintText: 'e.g. Air University Hostel',
              border: OutlineInputBorder(),
            ),
            validator: Validators.flatName,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogCtx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true && context.mounted) {
      await ref.read(householdActionsProvider.notifier).rename(
            householdId: householdId,
            name: controller.text.trim(),
          );
      if (context.mounted) {
        showAppSnack(context, 'Flat renamed to "${controller.text.trim()}".');
      }
    }
  }

  Future<void> _leaveFlat(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave flat?',
      message:
          'You will be removed from this flat and need an invite code to join again.',
      confirmLabel: 'Leave',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(householdActionsProvider.notifier).leave();
      if (context.mounted) {
        showAppSnack(context, 'You left the flat.');
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in anytime — your flat and expenses stay put.',
      confirmLabel: 'Sign out',
    );
    if (confirmed == true) {
      await ref.read(authActionsProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = ref.watch(sessionProvider).value;
    final household = ref.watch(currentHouseholdProvider).value;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    final user = session?.user;
    final isOwner = household != null && household.ownerId == user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile Card
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              onTap: () => context.push(Routes.profile),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AppAvatar(
                      name: user?.name ?? '',
                      photoUrl: user?.photoUrl,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'CoSpend member',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Owner',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📞 ${user.phone}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Flat & Budget Section
          if (household != null) ...[
            Text(
              'FLAT SETTINGS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_work_rounded),
                    title: const Text('Flat name'),
                    subtitle: Text(household.name),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () => _renameFlat(
                      context,
                      ref,
                      household.id,
                      household.name,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.pie_chart_rounded),
                    title: const Text('Category Budgets'),
                    subtitle: Text(
                      isOwner
                          ? (household.effectiveTotalBudgetPaisa > 0
                              ? '${Money.format(household.effectiveTotalBudgetPaisa)} target (${household.categoryBudgetsPaisa.length} categories)'
                              : 'Set limits for Food, Bills, etc.')
                          : (household.effectiveTotalBudgetPaisa > 0
                              ? 'View limits: ${Money.format(household.effectiveTotalBudgetPaisa)} target'
                              : 'View limits (Managed by flat owner)'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.categoryBudgets),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_add_rounded),
                    title: const Text('Join another flat'),
                    subtitle: const Text('Enter an invite code from roommates'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.joinFlat),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.share_rounded),
                    title: const Text('Invite flatmates'),
                    subtitle: Text('Invite code: ${household.inviteCode}'),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () =>
                        InviteMembersSheet.show(context, household),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: scheme.error),
                    title: Text(
                      'Leave flat',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => _leaveFlat(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Appearance Section
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (selected) {
                if (selected != null) {
                  ref.read(themeModeProvider.notifier).setMode(selected);
                }
              },
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(_themeModeLabel(mode)),
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Tour / Onboarding
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.auto_stories_rounded),
              title: const Text('App Tour & Features'),
              subtitle: const Text('Replay animated onboarding introduction'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.onboarding),
            ),
          ),
          const SizedBox(height: 12),

          // Account Actions
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.power_settings_new_rounded, color: scheme.error),
              title: Text(
                'Sign out',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              '${AppConstants.appName} · v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light mode',
        ThemeMode.dark => 'Dark mode',
      };
}