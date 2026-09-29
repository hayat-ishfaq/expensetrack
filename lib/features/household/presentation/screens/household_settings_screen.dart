import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';

class HouseholdSettingsScreen extends ConsumerWidget {
  const HouseholdSettingsScreen({super.key});

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final controller = TextEditingController(text: household.name);
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename flat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Flat name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (updated == true && context.mounted) {
      await ref.read(householdActionsProvider.notifier).rename(
            householdId: household.id,
            name: controller.text.trim(),
          );
      if (context.mounted) {
        showAppSnack(context, 'Flat renamed.');
      }
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
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
      if (context.mounted) showAppSnack(context, 'You left the flat.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final members = ref.watch(householdMembersProvider).value ?? const [];
    final uid = ref.watch(sessionProvider).value?.user?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwner = household != null && household.ownerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household settings'),
      ),
      body: household == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  household.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? 'You own this flat'
                      : 'Managed by the flat owner',
                  style: TextStyle(
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                CoSpendCard(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const TintedIcon(
                          icon: Icons.vpn_key_rounded,
                          color: CoSpendColors.jadeGreen,
                        ),
                        title: const Text('Invite code'),
                        subtitle: Text(household.inviteCode),
                        trailing: IconButton(
                          tooltip: 'Copy code',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: household.inviteCode),
                            );
                            showAppSnack(context, 'Invite code copied.');
                          },
                        ),
                        onTap: () =>
                            InviteMembersSheet.show(context, household),
                      ),
                      if (isOwner)
                        ListTile(
                          leading: const TintedIcon(
                            icon: Icons.edit_rounded,
                            color: CoSpendColors.prussianBlue,
                          ),
                          title: const Text('Rename flat'),
                          onTap: () => _rename(context, ref, household),
                        ),
                      ListTile(
                        leading: const TintedIcon(
                          icon: Icons.swap_horiz_rounded,
                          color: Color(0xFF0EA5E9),
                        ),
                        title: const Text('Settle up'),
                        subtitle: const Text('Balances and recorded transfers'),
                        onTap: () => context.push(Routes.settle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(
                  'Members (${members.length})',
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                CoSpendCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      for (final member in members)
                        ListTile(
                          leading: AppAvatar(
                            name: member.name,
                            photoUrl: member.photoUrl,
                            size: 40,
                          ),
                          title: Text(member.name),
                          subtitle: Text(member.email),
                          trailing: Text(
                            member.role == MemberRole.owner ? 'Owner' : 'Member',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => _leave(context, ref),
                  child: const Text(
                    'Leave flat',
                    style: TextStyle(
                      color: CoSpendColors.alertRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
