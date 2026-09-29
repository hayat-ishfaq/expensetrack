import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/providers/notification_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';
import '../../../household/presentation/widgets/notifications_sheet.dart';
import '../../../settlement/presentation/providers/settlement_providers.dart';

/// The core Fintech Dashboard for the household.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dashboardMonthProvider);
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month + 1, 0),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      ref.read(dashboardMonthProvider.notifier).setMonth(
            DateTime(picked.year, picked.month),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final session = ref.watch(sessionProvider).value;
    final currentUser = ref.watch(currentUserProvider).value ?? session?.user;
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final recentExpensesAsync = ref.watch(recentExpensesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final budgetStatus = ref.watch(budgetStatusProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final exceededAlerts = ref.watch(exceededBudgetAlertsProvider);
    final settlementAsync = ref.watch(settlementProvider);

    final currentUserId = currentUser?.id ?? '';
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final userName = currentUser?.name ?? 'Roommate';
    final userPhotoUrl = currentUser?.photoUrl;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'DASHBOARD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
        actions: [
          householdAsync.maybeWhen(
            data: (household) {
              if (household == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Badge(
                      isLabelVisible: unreadNotifs > 0,
                      backgroundColor: CoSpendColors.alertRed,
                      label: Text('$unreadNotifs'),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white70 : CoSpendColors.textMuted,
                        size: 22,
                      ),
                    ),
                    tooltip: 'Activity & Alerts',
                    onPressed: () {
                      NotificationsSheet.show(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => context.push(Routes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CoSpendColors.jadeGreen,
                            width: 2,
                          ),
                        ),
                        child: AppAvatar(
                          name: userName,
                          photoUrl: userPhotoUrl,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: householdAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (error, _) => ErrorView(
          message: error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          onRetry: () => ref.invalidate(currentHouseholdProvider),
        ),
        data: (household) {
          if (household == null) {
            return const EmptyState(
              icon: Icons.home_outlined,
              title: 'No flat yet',
              message: 'Create or join a flat to start sharing expenses.',
            );
          }

          final members = membersAsync.value ?? const [];
          final memberNameMap = {for (final m in members) m.id: m.name};

          final settlement = settlementAsync.value;
          // Current user's net balance: positive = owed to them, negative = they owe
          final myBalance = settlement?.balances
              .where((b) => b.memberId == currentUserId)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              // ── Greeting + Month Selector + Invite Code ──────────────────
              _HeaderSection(
                greeting: _greeting(),
                userName: userName,
                selectedMonth: selectedMonth,
                inviteCode: household.inviteCode,
                onMonthTap: () => _pickMonth(context, ref),
                onInviteTap: () => InviteMembersSheet.show(context, household),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // ── Hero Total Monthly Spend Card ─────────────────────────────
              _HeroSpendCard(
                totalSpendingPaisa: stats.totalSpendingPaisa,
                budgetPaisa: household.effectiveTotalBudgetPaisa,
                sharedSpendingPaisa: stats.totalSpendingPaisa - stats.userPaidPaisa,
                individualSpendingPaisa: stats.userPaidPaisa,
                budgetStatus: budgetStatus,
              ),
              const SizedBox(height: 14),

              // ── 2×2 Stats Grid ────────────────────────────────────────────
              _StatsGrid(
                totalBudgetPaisa: household.effectiveTotalBudgetPaisa,
                totalSpendingPaisa: stats.totalSpendingPaisa,
                userSharePaisa: stats.userSharePaisa,
                userPaidPaisa: stats.userPaidPaisa,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // ── Budget Alerts ─────────────────────────────────────────────
              if (exceededAlerts.isNotEmpty) ...[
                for (final alert in exceededAlerts)
                  _BudgetAlertBanner(
                    label: alert.label,
                    mySpentPaisa: alert.mySpentPaisa,
                    myBudgetPaisa: alert.myBudgetPaisa,
                    isDark: isDark,
                  ),
              ],

              // ── Recent Activity ───────────────────────────────────────────
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(Routes.expenses),
                    child: Row(
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent expense tiles
              recentExpensesAsync.when(
                loading: () => const Column(
                  children: [
                    SkeletonBox(height: 64),
                    SizedBox(height: 8),
                    SkeletonBox(height: 64),
                  ],
                ),
                error: (error, _) => Text(
                  FirebaseErrorMapper.messageFor(error),
                  style: TextStyle(color: scheme.error),
                ),
                data: (recent) {
                  if (recent.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                        borderRadius: CoSpendRadii.cardRadius,
                        border: Border.all(
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : CoSpendColors.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 32, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'No expenses recorded yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button below to add your first expense.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                      borderRadius: CoSpendRadii.cardRadius,
                      border: Border.all(
                        color: isDark
                            ? CoSpendColors.darkBorder
                            : CoSpendColors.borderLight,
                        width: 0.8,
                      ),
                      boxShadow: isDark ? null : CoSpendShadows.card,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < recent.length; i++) ...[
                          _RecentActivityTile(
                            description: recent[i].description,
                            amountPaisa: recent[i].amountPaisa,
                            category: recent[i].category,
                            customCategoryId: recent[i].customCategoryId,
                            subcategory: recent[i].subcategory,
                            spentAt: recent[i].spentAt,
                            payerName: memberNameMap[recent[i].paidById] ?? 'Flatmate',
                            onTap: () {
                              context.push(
                                Routes.expenseDetails.replaceAll(':id', recent[i].id),
                                extra: recent[i],
                              );
                            },
                            isDark: isDark,
                          ),
                          if (i < recent.length - 1)
                            Divider(
                              height: 1,
                              color: isDark
                                  ? CoSpendColors.darkBorder
                                  : CoSpendColors.borderLight,
                              indent: 68,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Quick Insights ────────────────────────────────────────────
              Text(
                'Quick Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 12),
              _QuickInsightsRow(
                myBalance: myBalance?.netPaisa ?? 0,
                memberNameMap: memberNameMap,
                settlement: settlementAsync.value,
                currentUserId: currentUserId,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BouncingButton(
        onTap: () => context.push(Routes.addExpense),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: CoSpendShadows.floating,
          ),
          child: const CircleAvatar(
            radius: 28,
            backgroundColor: CoSpendColors.jadeGreen,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Section Widget
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.greeting,
    required this.userName,
    required this.selectedMonth,
    required this.inviteCode,
    required this.onMonthTap,
    required this.onInviteTap,
    required this.isDark,
  });

  final String greeting;
  final String userName;
  final DateTime selectedMonth;
  final String inviteCode;
  final VoidCallback onMonthTap;
  final VoidCallback onInviteTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${userName.split(' ').first}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onMonthTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(selectedMonth),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : CoSpendColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onInviteTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
              borderRadius: CoSpendRadii.pillRadius,
              border: Border.all(
                color: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
                width: 1,
              ),
              boxShadow: isDark ? null : CoSpendShadows.cardSubtle,
            ),
            child: Text(
              inviteCode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Spend Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSpendCard extends StatelessWidget {
  const _HeroSpendCard({
    required this.totalSpendingPaisa,
    required this.budgetPaisa,
    required this.sharedSpendingPaisa,
    required this.individualSpendingPaisa,
    this.budgetStatus,
  });

  final int totalSpendingPaisa;
  final int budgetPaisa;
  final int sharedSpendingPaisa;
  final int individualSpendingPaisa;
  final BudgetStatus? budgetStatus;

  @override
  Widget build(BuildContext context) {
    final pct = budgetStatus?.percentage ?? 0.0;
    final clampedPct = pct.clamp(0.0, 100.0);
    final isExceeded = budgetStatus?.isExceeded ?? false;
    final isApproaching = budgetStatus?.isApproaching ?? false;
    final progressColor = isExceeded
        ? CoSpendColors.alertRed
        : isApproaching
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: CoSpendRadii.cardLargeRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1F3D),
            Color(0xFF0E2D5A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CoSpendColors.prussianBlue.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: label + wallet icon ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Monthly Spend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: CoSpendColors.jadeGreen,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Total amount ──────────────────────────────────────────────────
          Text(
            Money.format(totalSpendingPaisa),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // ── Budget Limit Row ──────────────────────────────────────────────
          if (budgetPaisa > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Limit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  Money.format(budgetPaisa),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Progress Bar ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: CoSpendRadii.pillRadius,
              child: Stack(
                children: [
                  Container(
                    height: 7,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: clampedPct / 100.0),
                    builder: (context, value, child) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: CoSpendRadii.pillRadius,
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${clampedPct.toStringAsFixed(0)}% of limit used',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
          ],

          // ── Shared / Individual Split ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SpendSplitTile(
                  label: 'SHARED',
                  amountPaisa: sharedSpendingPaisa,
                  icon: Icons.trending_up_rounded,
                  iconColor: CoSpendColors.jadeGreen,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _SpendSplitTile(
                  label: 'INDIVIDUAL',
                  amountPaisa: individualSpendingPaisa,
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendSplitTile extends StatelessWidget {
  const _SpendSplitTile({
    required this.label,
    required this.amountPaisa,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final int amountPaisa;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Money.format(amountPaisa),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2×2 Stats Grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalBudgetPaisa,
    required this.totalSpendingPaisa,
    required this.userSharePaisa,
    required this.userPaidPaisa,
    required this.isDark,
  });

  final int totalBudgetPaisa;
  final int totalSpendingPaisa;
  final int userSharePaisa;
  final int userPaidPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final budgetUsedPct = totalBudgetPaisa > 0
        ? ((totalSpendingPaisa / totalBudgetPaisa) * 100).round()
        : 0;
    final remainingPaisa = (userSharePaisa - userPaidPaisa).abs();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: CoSpendColors.jadeGreen,
                label: 'TOTAL BUDGET',
                value: Money.format(totalBudgetPaisa),
                subtitle: 'Household limit',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF60A5FA),
                label: 'TOTAL SPENDINGS',
                value: Money.format(totalSpendingPaisa),
                subtitle: totalBudgetPaisa > 0
                    ? '$budgetUsedPct% of flat budget used'
                    : 'This month',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFFA78BFA),
                label: 'YOUR SHARE',
                value: Money.format(userSharePaisa),
                subtitle: 'Your allocated quota',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.home_outlined,
                iconColor: const Color(0xFFFB923C),
                label: 'SPENT BY YOU',
                value: Money.format(userPaidPaisa),
                subtitle: userPaidPaisa <= userSharePaisa
                    ? '${Money.format(remainingPaisa)} remaining'
                    : '${Money.format(remainingPaisa)} over',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          width: 0.8,
        ),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Alert Banner
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetAlertBanner extends StatelessWidget {
  const _BudgetAlertBanner({
    required this.label,
    required this.mySpentPaisa,
    required this.myBudgetPaisa,
    required this.isDark,
  });

  final String label;
  final int mySpentPaisa;
  final int myBudgetPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = myBudgetPaisa > 0
        ? ((mySpentPaisa / myBudgetPaisa) * 100).round()
        : 85;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1015) : const Color(0xFFFFF5F5),
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: CoSpendColors.alertRed.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CoSpendColors.alertRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.error_outline_rounded,
              color: CoSpendColors.alertRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Alert: $label Spending',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: CoSpendColors.alertRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your group has spent $pct% of the $label budget. Consider reviewing upcoming needs.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: CoSpendColors.alertRed,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Tile
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivityTile extends ConsumerWidget {
  const _RecentActivityTile({
    required this.description,
    required this.amountPaisa,
    required this.category,
    this.customCategoryId,
    this.subcategory,
    required this.spentAt,
    required this.payerName,
    required this.onTap,
    required this.isDark,
  });

  final String description;
  final int amountPaisa;
  final dynamic category;
  final String? customCategoryId;
  final String? subcategory;
  final DateTime spentAt;
  final String payerName;
  final VoidCallback onTap;
  final bool isDark;

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today, ${DateFormat('hh:mm a').format(date)}';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == customCategoryId)
            .firstOrNull
        : null;
    final catIcon = custom?.icon ?? category.icon as IconData;
    final catColor = custom?.color ?? category.color as Color;
    final catLabel = custom?.label ?? category.label as String;

    return InkWell(
      onTap: onTap,
      borderRadius: CoSpendRadii.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(catIcon, size: 20, color: catColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        catLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                      Text(
                        ' · ${_relativeDate(spentAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '- ${Money.format(amountPaisa)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Insights Row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickInsightsRow extends StatelessWidget {
  const _QuickInsightsRow({
    required this.myBalance,
    required this.memberNameMap,
    required this.settlement,
    required this.currentUserId,
    required this.isDark,
  });

  final int myBalance;
  final Map<String, String> memberNameMap;
  final dynamic settlement;
  final String currentUserId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Find someone they owe to
    String owesTo = '';
    int owesAmount = 0;
    String owedBy = '';
    int owedAmount = 0;

    if (settlement != null) {
      for (final transfer in settlement!.transfers) {
        if (transfer.fromMemberId == currentUserId) {
          // user owes someone
          owesTo = memberNameMap[transfer.toMemberId] ?? 'Flatmate';
          owesAmount = transfer.amountPaisa;
          break;
        }
      }
      for (final transfer in settlement!.transfers) {
        if (transfer.toMemberId == currentUserId) {
          // someone owes the user
          owedBy = memberNameMap[transfer.fromMemberId] ?? 'Flatmate';
          owedAmount = transfer.amountPaisa;
          break;
        }
      }
    }

    final cardBg = isDark ? CoSpendColors.darkCard : CoSpendColors.white;
    final borderColor =
        isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Row(
        children: [
          // Settlements
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 15,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SETTLEMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    owedAmount > 0
                        ? '${owedBy.split(' ').first} owes you'
                        : 'All settled up',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owedAmount > 0
                        ? Money.format(owedAmount)
                        : Money.format(0),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: owedAmount > 0
                          ? CoSpendColors.jadeGreen
                          : (isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
          // Balance
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 15,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    owesAmount > 0
                        ? 'You owe ${owesTo.split(' ').first}'
                        : 'No pending dues',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owesAmount > 0
                        ? Money.format(owesAmount)
                        : Money.format(0),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: owesAmount > 0
                          ? CoSpendColors.alertRed
                          : (isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 60),
        SizedBox(height: 16),
        SkeletonBox(height: 200),
        SizedBox(height: 16),
        SkeletonBox(height: 64),
        SizedBox(height: 8),
        SkeletonBox(height: 64),
        SizedBox(height: 8),
        SkeletonBox(height: 64),
        SizedBox(height: 20),
        SkeletonBox(height: 110),
      ],
    );
  }
}