import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
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
          CoSpendCard(
            onTap: () => context.push(Routes.profile),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CoSpendColors.prussianBlue.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                  child: AppAvatar(
                    name: user?.name ?? '',
                    photoUrl: user?.photoUrl,
                    size: 46,
                  ),
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
                                color: CoSpendColors.prussianBlue,
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
                                color: CoSpendColors.prussianBlue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  color: CoSpendColors.prussianBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📞 ${user.phone}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CoSpendColors.jadeGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const TintedIcon(
                  icon: Icons.edit_outlined,
                  size: 16,
                  color: CoSpendColors.prussianBlue,
                  containerSize: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Flat & Budget Section
          if (household != null) ...[
            const SectionLabel('FLAT SETTINGS'),
            const SizedBox(height: 6),
            CoSpendCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.groups_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Household & Roommates',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${household.name} · Roster & permissions',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    onTap: () => context.push(Routes.householdSettings),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.home_work_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Flat name',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      household.name,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                    onTap: () => _renameFlat(
                      context,
                      ref,
                      household.id,
                      household.name,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.pie_chart_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Category Budgets',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isOwner
                          ? (household.effectiveTotalBudgetPaisa > 0
                              ? '${Money.format(household.effectiveTotalBudgetPaisa)} target (${household.categoryBudgetsPaisa.length} categories)'
                              : 'Set limits for Food, Bills, etc.')
                          : (household.effectiveTotalBudgetPaisa > 0
                              ? 'View limits: ${Money.format(household.effectiveTotalBudgetPaisa)} target'
                              : 'View limits (Managed by flat owner)'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    onTap: () => context.push(Routes.categoryBudgets),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.swap_horiz_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Settle Up & Reconciliation',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Who owes whom, optimized transfers',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    onTap: () => context.push(Routes.settlementHistory),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.group_add_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Join another flat',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Enter an invite code from roommates',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    onTap: () => context.push(Routes.joinFlat),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.share_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Invite flatmates',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Invite code: ${household.inviteCode}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onTap: () =>
                        InviteMembersSheet.show(context, household),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x0F0A2542)),
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.logout_rounded,
                      color: CoSpendColors.alertRed,
                      size: 20,
                    ),
                    title: const Text(
                      'Leave flat',
                      style: TextStyle(
                        color: CoSpendColors.alertRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => _leaveFlat(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Appearance Section
          const SectionLabel('APPEARANCE'),
          const SizedBox(height: 6),
          CoSpendCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < ThemeMode.values.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x0F0A2542)),
                  InkWell(
                    onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.values[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            _themeModeLabel(ThemeMode.values[i]),
                            style: TextStyle(
                              fontWeight: themeMode == ThemeMode.values[i] ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                              color: themeMode == ThemeMode.values[i] ? CoSpendColors.prussianBlue : const Color(0xFF374151),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeMode == ThemeMode.values[i] ? CoSpendColors.jadeGreen : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: themeMode == ThemeMode.values[i]
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: CoSpendColors.jadeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Tour / Onboarding
          CoSpendCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const TintedIcon(
                icon: Icons.auto_stories_rounded,
                color: CoSpendColors.prussianBlue,
                size: 20,
              ),
              title: const Text(
                'App Tour & Features',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Replay animated onboarding introduction',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
              onTap: () => context.push(Routes.onboarding),
            ),
          ),
          const SizedBox(height: 12),

          // Account Actions
          CoSpendCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const TintedIcon(
                icon: Icons.power_settings_new_rounded,
                color: CoSpendColors.alertRed,
                size: 20,
              ),
              title: const Text(
                'Sign out',
                style: TextStyle(
                  color: CoSpendColors.alertRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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