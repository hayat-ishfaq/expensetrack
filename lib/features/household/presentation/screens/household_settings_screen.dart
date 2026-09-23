import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../providers/household_providers.dart';
import '../widgets/invite_members_sheet.dart';

/// Comprehensive Household & Flat Management Screen.
class HouseholdSettingsScreen extends ConsumerStatefulWidget {
  const HouseholdSettingsScreen({super.key});

  @override
  ConsumerState<HouseholdSettingsScreen> createState() =>
      _HouseholdSettingsScreenState();
}

class _HouseholdSettingsScreenState
    extends ConsumerState<HouseholdSettingsScreen> {
  bool _isLeaving = false;

  Future<void> _renameFlat(Household household) async {
    final controller = TextEditingController(text: household.name);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? CoSpendColors.darkCard : Colors.white,
          title: Text(
            'Rename Flat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Flat Name',
                hintText: 'e.g. Air University Hostel',
                prefixIcon: Icon(Icons.home_work_rounded),
              ),
              validator: Validators.flatName,
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
        );
      },
    );

    if (updated == true && mounted) {
      final newName = controller.text.trim();
      try {
        await ref.read(householdActionsProvider.notifier).rename(
              householdId: household.id,
              name: newName,
            );
        if (mounted) {
          showAppSnack(context, 'Flat renamed to "$newName"');
        }
      } catch (e) {
        if (mounted) {
          showAppSnack(context, 'Failed to rename flat: $e', error: true);
        }
      }
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      showAppSnack(context, 'Invite code copied: $code');
    }
  }

  Future<void> _leaveFlat(Household household) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave flat?',
      message:
          'You will be removed from "${household.name}". You will need an invite code to rejoin. Your historical expenses will stay in the flat record.',
      confirmLabel: 'Leave Flat',
      destructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isLeaving = true);
      try {
        await ref.read(householdActionsProvider.notifier).leave();
        if (mounted) {
          showAppSnack(context, 'You left ${household.name}.');
          context.go(Routes.home);
        }
      } catch (e) {
        if (mounted) {
          showAppSnack(context, 'Failed to leave flat: $e', error: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLeaving = false);
        }
      }
    }
  }

  String _formatJoinedDate(DateTime joinedAt) {
    final diff = DateTime.now().difference(joinedAt);
    if (diff.inDays == 0) return 'Joined today';
    if (diff.inDays == 1) return 'Joined yesterday';
    if (diff.inDays < 30) return 'Joined ${diff.inDays}d ago';
    if (diff.inDays < 365) return 'Joined ${(diff.inDays / 30).round()}mo ago';
    return 'Joined ${joinedAt.day}/${joinedAt.month}/${joinedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final session = ref.watch(sessionProvider).value;
    final user = session?.user;
    final household = ref.watch(currentHouseholdProvider).value;
    final membersAsync = ref.watch(householdMembersProvider);
    final members = membersAsync.value ?? const [];

    if (household == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flat Settings')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_work_outlined, size: 48, color: CoSpendColors.textSubtle),
              const SizedBox(height: 12),
              const Text('No flat found', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.go(Routes.createFlat),
                child: const Text('Create or Join Flat'),
              ),
            ],
          ),
        ),
      );
    }

    final isOwner = user != null && household.ownerId == user.id;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        title: const Text('Household Management'),
        actions: [
          IconButton(
            tooltip: 'Invite Members',
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () => InviteMembersSheet.show(context, household),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. HOUSEHOLD HERO CARD
          _HouseholdHeroCard(
            household: household,
            isDark: isDark,
            isOwner: isOwner,
            memberCount: members.length,
            onRename: isOwner ? () => _renameFlat(household) : null,
          ),
          const SizedBox(height: 16),

          // 2. INVITE CODE SHOWCASE
          const SectionLabel('ROOMMATE INVITE CODE'),
          const SizedBox(height: 8),
          _InviteCodeCard(
            inviteCode: household.inviteCode,
            isDark: isDark,
            onCopy: () => _copyCode(household.inviteCode),
            onShare: () => InviteMembersSheet.show(context, household),
          ),
          const SizedBox(height: 20),

          // 3. MEMBER ROSTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel('FLATMATES (${members.length})'),
              TextButton.icon(
                onPressed: () => InviteMembersSheet.show(context, household),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Invite', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: CoSpendColors.jadeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MembersRosterList(
            members: members,
            currentUserId: user?.id,
            isDark: isDark,
            formatDate: _formatJoinedDate,
          ),
          const SizedBox(height: 20),

          // 4. OWNER VS MEMBER MANAGEMENT SECTION
          SectionLabel(isOwner ? 'OWNER MANAGEMENT' : 'FLAT OVERVIEW'),
          const SizedBox(height: 8),
          CoSpendCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Category Budgets
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.pie_chart_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: Text(
                      isOwner ? 'Category Budgets & Limits' : 'Category Spending & Limits',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      isOwner
                          ? (household.effectiveTotalBudgetPaisa > 0
                              ? '${Money.format(household.effectiveTotalBudgetPaisa)} monthly cap (${household.categoryBudgetsPaisa.length} categories)'
                              : 'Set caps for Food, Bills, Rent, etc.')
                          : (household.effectiveTotalBudgetPaisa > 0
                              ? 'Target: ${Money.format(household.effectiveTotalBudgetPaisa)} · Managed by flat owner'
                              : 'View limits (Managed by household owner)'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: CoSpendColors.textSubtle),
                    onTap: () => context.push(Routes.categoryBudgets),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),

                  // Settle Up
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.swap_horiz_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 20,
                    ),
                    title: const Text(
                      'Settle Up & Balances',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Who owes whom, optimized direct transfers',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: CoSpendColors.textSubtle),
                    onTap: () => context.push(Routes.settlementHistory),
                  ),

                  if (isOwner) ...[
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    ListTile(
                      leading: const TintedIcon(
                        icon: Icons.edit_note_rounded,
                        color: CoSpendColors.prussianBlue,
                        size: 20,
                      ),
                      title: const Text(
                        'Rename Flat',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Current name: ${household.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: CoSpendColors.textSubtle),
                      onTap: () => _renameFlat(household),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. DANGEROUS ACTIONS
          const SectionLabel('DANGER ZONE'),
          const SizedBox(height: 8),
          CoSpendCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.logout_rounded,
                      color: CoSpendColors.alertRed,
                      size: 20,
                    ),
                    title: const Text(
                      'Leave Flat',
                      style: TextStyle(
                        color: CoSpendColors.alertRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isOwner
                          ? 'Leave flat and transfer ownership'
                          : 'Remove yourself from "${household.name}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                    trailing: _isLeaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: CoSpendColors.alertRed,
                          ),
                    onTap: _isLeaving ? null : () => _leaveFlat(household),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// =============================================================================
// 1. HOUSEHOLD HERO CARD
// =============================================================================

class _HouseholdHeroCard extends StatelessWidget {
  const _HouseholdHeroCard({
    required this.household,
    required this.isDark,
    required this.isOwner,
    required this.memberCount,
    this.onRename,
  });

  final Household household;
  final bool isDark;
  final bool isOwner;
  final int memberCount;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? CoSpendColors.prussianBlueMedium.withValues(alpha: 0.6)
                      : CoSpendColors.prussianBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 22,
                  color: CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created ${household.createdAt.day}/${household.createdAt.month}/${household.createdAt.year}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRename != null)
                Semantics(
                  button: true,
                  label: 'Rename Flat ${household.name}',
                  child: IconButton(
                    tooltip: 'Rename Flat',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onRename,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Status & Role Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Active Flat Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CoSpendColors.jadeGreen.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CoSpendColors.jadeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active Flat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CoSpendColors.jadeGreen,
                      ),
                    ),
                  ],
                ),
              ),

              // Member Count Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? CoSpendColors.prussianBlueMedium
                      : CoSpendColors.prussianBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_rounded, size: 13, color: CoSpendColors.prussianBlue),
                    const SizedBox(width: 5),
                    Text(
                      '$memberCount Flatmates',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Owner / Member Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOwner
                      ? (isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
                          : const Color(0xFFE0E7FF))
                      : (isDark ? CoSpendColors.darkBorder : const Color(0x140A2542)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOwner ? Icons.workspace_premium_rounded : Icons.person_rounded,
                      size: 13,
                      color: isOwner
                          ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3))
                          : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOwner ? 'You are Owner' : 'You are Member',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOwner
                            ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3))
                            : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. INVITE CODE SHOWCASE CARD
// =============================================================================

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.inviteCode,
    required this.isDark,
    required this.onCopy,
    required this.onShare,
  });

  final String inviteCode;
  final bool isDark;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JOIN CODE FOR ROOMMATES',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? CoSpendColors.darkTextSubtle : CoSpendColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: CoSpendColors.jadeGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Copy invite code $inviteCode',
                child: IconButton.filledTonal(
                  tooltip: 'Copy Code',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Share this code with flatmates. They can enter it during sign-up or under "Join another flat".',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Code'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share Invite'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. MEMBER ROSTER LIST
// =============================================================================

class _MembersRosterList extends StatelessWidget {
  const _MembersRosterList({
    required this.members,
    required this.currentUserId,
    required this.isDark,
    required this.formatDate,
  });

  final List<HouseholdMember> members;
  final String? currentUserId;
  final bool isDark;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const CoSpendCard(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No members found',
            style: TextStyle(color: CoSpendColors.textSubtle),
          ),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        final isMe = member.id == currentUserId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CoSpendCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                AppAvatar(
                  name: member.name,
                  photoUrl: member.photoUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),

                // Member Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name.isNotEmpty ? member.name : 'Flatmate',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: CoSpendColors.jadeGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: CoSpendColors.jadeGreen,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (member.phone != null && member.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📞 ${member.phone}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CoSpendColors.jadeGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Role & Joined Tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (member.isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
                              : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : const Color(0x0F0A2542),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Member',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(member.joinedAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? CoSpendColors.darkTextSubtle : CoSpendColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
