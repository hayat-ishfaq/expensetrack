import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/avatar_picker_sheet.dart';

/// Premium financial/lifestyle profile screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLeavingFlat = false;

  Future<void> _openAvatarStudio(AppUser user) async {
    final selected = await AvatarPickerSheet.show(
      context,
      currentAvatarUrl: user.photoUrl,
      name: user.name.isNotEmpty ? user.name : 'User',
    );

    if (selected == null || !mounted) return;

    try {
      await ref.read(authActionsProvider.notifier).updateProfile(
            uid: user.id,
            name: user.name,
            photoUrl: selected.isEmpty ? null : selected,
            phone: user.phone,
            upiId: user.upiId,
            bio: user.bio,
            householdId: user.householdId,
          );
      ref.invalidate(currentUserProvider);
      ref.invalidate(sessionProvider);
      if (mounted) {
        showAppSnack(context, 'Avatar updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Failed to update avatar: $e', error: true);
      }
    }
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showAppSnack(context, '$label copied to clipboard');
    }
  }

  Future<void> _leaveFlat(Household household) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave flat?',
      message:
          'You will be removed from "${household.name}" and need an invite code to rejoin. Your historical expenses will stay in the flat record.',
      confirmLabel: 'Leave Flat',
      destructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isLeavingFlat = true);
      try {
        await ref.read(householdActionsProvider.notifier).leave();
        if (mounted) {
          showAppSnack(context, 'You left ${household.name}.');
          if (context.canPop()) {
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          showAppSnack(context, 'Failed to leave flat: $e', error: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLeavingFlat = false);
        }
      }
    }
  }

  Future<void> _confirmSignOut() async {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(sessionProvider).value;
    final user = session?.user;
    final household = ref.watch(currentHouseholdProvider).value;
    final members = ref.watch(householdMembersProvider).value ?? const [];

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User profile not available')),
      );
    }

    final isOwner = household != null && household.ownerId == user.id;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. PROFILE HEADER
          _ProfileHeader(
            user: user,
            isDark: isDark,
            isOwner: isOwner,
            householdName: household?.name,
            onAvatarTap: () => _openAvatarStudio(user),
            onEditTap: () => context.push(Routes.editProfile),
          ),
          const SizedBox(height: 16),

          // 2. ACCOUNT INFORMATION
          const SectionLabel('ACCOUNT INFORMATION'),
          const SizedBox(height: 8),
          _AccountInfoSection(
            user: user,
            isDark: isDark,
            onCopy: _copyText,
            onEdit: () => context.push(Routes.editProfile),
          ),
          const SizedBox(height: 20),

          // 3. HOUSEHOLD SECTION
          if (household != null) ...[
            const SectionLabel('HOUSEHOLD & FLAT'),
            const SizedBox(height: 8),
            _HouseholdSummaryCard(
              household: household,
              isDark: isDark,
              isOwner: isOwner,
              memberCount: members.length,
              onCopyCode: () => _copyText(household.inviteCode, 'Invite code'),
              onManageHousehold: () => context.push(Routes.householdSettings),
              onInviteTap: () => InviteMembersSheet.show(context, household),
            ),
            const SizedBox(height: 20),
          ],

          // 4. DANGEROUS ACTIONS / ACCOUNT CONTROLS
          const SectionLabel('ACCOUNT ACTIONS'),
          const SizedBox(height: 8),
          CoSpendCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  if (household != null && !isOwner) ...[
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
                        'Remove yourself from ${household.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                      trailing: _isLeavingFlat
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: CoSpendColors.alertRed,
                            ),
                      onTap: _isLeavingFlat ? null : () => _leaveFlat(household),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                  ListTile(
                    leading: const TintedIcon(
                      icon: Icons.power_settings_new_rounded,
                      color: CoSpendColors.alertRed,
                      size: 20,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: CoSpendColors.alertRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Log out of ${AppConstants.appName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: CoSpendColors.alertRed,
                    ),
                    onTap: _confirmSignOut,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              '${AppConstants.appName} · v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? CoSpendColors.darkTextSubtle
                    : CoSpendColors.textSubtle,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// =============================================================================
// 1. PROFILE HEADER
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.isOwner,
    required this.householdName,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  final AppUser user;
  final bool isDark;
  final bool isOwner;
  final String? householdName;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Hero Avatar with camera trigger
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? CoSpendColors.jadeGreen.withValues(alpha: 0.6)
                          : CoSpendColors.prussianBlue.withValues(alpha: 0.25),
                      width: 3,
                    ),
                    boxShadow: CoSpendShadows.softCard,
                  ),
                  child: AppAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    size: 88,
                    onTap: onAvatarTap,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAvatarTap,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: CoSpendColors.jadeGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? CoSpendColors.darkCard : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // User Name
          Text(
            user.name.isNotEmpty ? user.name : 'CoSpend Member',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email with security icon
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 13,
                color: CoSpendColors.jadeGreen,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges Row (Role + Flat)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOwner
                      ? (isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
                          : const Color(0xFFE0E7FF))
                      : (isDark
                          ? CoSpendColors.prussianBlueMedium
                          : CoSpendColors.prussianBlue.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOwner ? Icons.workspace_premium_rounded : Icons.person_rounded,
                      size: 14,
                      color: isOwner
                          ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3))
                          : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOwner ? 'Flat Owner' : 'Flatmate',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isOwner
                            ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3))
                            : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                      ),
                    ),
                  ],
                ),
              ),

              // Household Badge
              if (householdName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CoSpendColors.jadeGreen.withValues(alpha: 0.15)
                        : CoSpendColors.jadeGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.home_work_rounded,
                        size: 14,
                        color: CoSpendColors.jadeGreen,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          householdName!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: CoSpendColors.jadeGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit Profile Action CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Profile & Room Details'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. ACCOUNT INFORMATION SECTION
// =============================================================================

class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection({
    required this.user,
    required this.isDark,
    required this.onCopy,
    required this.onEdit,
  });

  final AppUser user;
  final bool isDark;
  final void Function(String text, String label) onCopy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Full Name
          _InfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: user.name.isNotEmpty ? user.name : 'Not set',
            isDark: isDark,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),

          // Email (Read-only)
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: user.email,
            isDark: isDark,
            trailing: const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: CoSpendColors.textSubtle,
            ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),

          // Phone / WhatsApp
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone / WhatsApp',
            value: (user.phone != null && user.phone!.isNotEmpty)
                ? user.phone!
                : 'Not provided',
            isDark: isDark,
            trailing: (user.phone != null && user.phone!.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copy Phone',
                    onPressed: () => onCopy(user.phone!, 'Phone number'),
                  )
                : TextButton(
                    onPressed: onEdit,
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),

          // UPI ID / Payment Handle
          _InfoTile(
            icon: Icons.payment_rounded,
            label: 'UPI ID / Payment Handle',
            value: (user.upiId != null && user.upiId!.isNotEmpty)
                ? user.upiId!
                : 'Not configured',
            isDark: isDark,
            trailing: (user.upiId != null && user.upiId!.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copy UPI Handle',
                    onPressed: () => onCopy(user.upiId!, 'UPI ID'),
                  )
                : TextButton(
                    onPressed: onEdit,
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),

          // Room / Bio Notes
          _InfoTile(
            icon: Icons.meeting_room_outlined,
            label: 'Room & Resident Notes',
            value: (user.bio != null && user.bio!.isNotEmpty)
                ? user.bio!
                : 'No notes added',
            isDark: isDark,
            trailing: (user.bio == null || user.bio!.isEmpty)
                ? TextButton(
                    onPressed: onEdit,
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TintedIcon(
            icon: icon,
            color: CoSpendColors.prussianBlue,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CoSpendColors.darkTextPrimary
                        : CoSpendColors.prussianBlue,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// =============================================================================
// 3. HOUSEHOLD SUMMARY CARD
// =============================================================================

class _HouseholdSummaryCard extends StatelessWidget {
  const _HouseholdSummaryCard({
    required this.household,
    required this.isDark,
    required this.isOwner,
    required this.memberCount,
    required this.onCopyCode,
    required this.onManageHousehold,
    required this.onInviteTap,
  });

  final Household household;
  final bool isDark;
  final bool isOwner;
  final int memberCount;
  final VoidCallback onCopyCode;
  final VoidCallback onManageHousehold;
  final VoidCallback onInviteTap;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Flat Name & Member Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? CoSpendColors.prussianBlueMedium.withValues(alpha: 0.6)
                      : CoSpendColors.prussianBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 20,
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
                        fontSize: 16,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$memberCount members · ${isOwner ? 'You are Owner' : 'Member'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                tooltip: 'Household Settings',
                onPressed: onManageHousehold,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Invite Code Prominent Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F253E)
                  : CoSpendColors.prussianBlue.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? CoSpendColors.darkBorder
                    : const Color(0x140A2542),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVITE CODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark
                            ? CoSpendColors.darkTextSubtle
                            : CoSpendColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      household.inviteCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: CoSpendColors.jadeGreen,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: CoSpendColors.jadeGreen,
                  ),
                ),
                TextButton.icon(
                  onPressed: onInviteTap,
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: CoSpendColors.prussianBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Manage Flat Settings Link
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onManageHousehold,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Manage Flat & Member Roster'),
            ),
          ),
        ],
      ),
    );
  }
}
