import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/providers/notification_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';
import '../../../household/presentation/widgets/notifications_sheet.dart';

/// Premium Fintech Dashboard for CoSpend.
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
      HapticFeedback.selectionClick();
      ref.read(dashboardMonthProvider.notifier).setMonth(
            DateTime(picked.year, picked.month),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final session = ref.watch(sessionProvider).value;
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final recentExpensesAsync = ref.watch(recentExpensesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final budgetStatus = ref.watch(budgetStatusProvider);
    final categoryBudgets = ref.watch(categoryBudgetsStatusProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final exceededAlerts = ref.watch(exceededBudgetAlertsProvider);

    final currentUserId = session?.user?.id ?? '';
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);

    // Listen for new flatmate spending notifications and display an in-app banner toast
    ref.listen(householdNotificationsProvider, (previous, next) {
      if (next.value != null && previous?.value != null) {
        final previousIds = previous!.value!.map((n) => n.id).toSet();
        for (final item in next.value!) {
          if (!previousIds.contains(item.id) && item.payerId != currentUserId) {
            showAppSnack(
              context,
              '🔔 ${item.title}: ${item.body}',
            );
          }
        }
      }
    });

    final userName = session?.user?.name ?? 'Roommate';

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      body: SafeArea(
        bottom: false,
        child: householdAsync.when(
          loading: () => const _HomeScreenSkeleton(),
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
                title: 'No household yet',
                message: 'Create or join a household to start sharing expenses.',
              );
            }

            final members = membersAsync.value ?? const [];
            final memberNameMap = {for (final m in members) m.id: m.name};
            final isOwner =
                household.ownerId.isEmpty || household.ownerId == currentUserId;

            return RefreshIndicator(
              color: CoSpendColors.jadeGreen,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.invalidate(currentHouseholdProvider);
                ref.invalidate(householdExpensesProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // 1. Top Header
                  _HomeHeader(
                    userName: userName,
                    photoUrl: session?.user?.photoUrl,
                    greeting: _greeting(),
                    budgetStatus: budgetStatus,
                    selectedMonth: selectedMonth,
                    unreadNotifs: unreadNotifs,
                    inviteCode: household.inviteCode,
                    onPickMonth: () => _pickMonth(context, ref),
                    onNotificationTap: () {
                      NotificationsSheet.show(context).then((_) {
                        if (context.mounted) {
                          ref
                              .read(lastViewedNotificationProvider.notifier)
                              .markAllAsRead();
                        }
                      });
                    },
                    onInviteTap: () =>
                        InviteMembersSheet.show(context, household),
                    onAvatarTap: () => context.push(Routes.profile),
                  ),
                  const SizedBox(height: 18),

                  // Exceeded Category Budget Alerts (if any)
                  if (exceededAlerts.isNotEmpty) ...[
                    for (final alert in exceededAlerts)
                      _BudgetAlertBanner(alert: alert, isDark: isDark),
                    const SizedBox(height: 14),
                  ],

                  // 2. Financial Hero Card
                  CoSpendFadeSlide(
                    offset: const Offset(0, 0.04),
                    child: _FinancialHeroCard(
                      budgetStatus: budgetStatus,
                      totalBudgetPaisa: household.effectiveTotalBudgetPaisa,
                      isOwner: isOwner,
                      onConfigureBudget: () =>
                          context.push(Routes.categoryBudgets),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Four Financial Metrics
                  _FourFinancialMetrics(
                    totalBudgetPaisa: household.effectiveTotalBudgetPaisa,
                    totalSpendingPaisa: stats.totalSpendingPaisa,
                    userAllocatedSharePaisa:
                        household.getMemberTotalBudget(currentUserId),
                    userSpentPaisa: stats.userPaidPaisa,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // 4. Budget Overview (Categories)
                  _BudgetOverviewSection(
                    categoryBudgets: categoryBudgets,
                    isOwner: isOwner,
                    isDark: isDark,
                    onManage: () => context.push(Routes.categoryBudgets),
                  ),
                  const SizedBox(height: 24),

                  // 5. Recent Activity
                  _RecentExpensesSection(
                    recentExpensesAsync: recentExpensesAsync,
                    memberNameMap: memberNameMap,
                    isDark: isDark,
                    onViewAll: () => context.go(Routes.expenses),
                    onExpenseTap: (exp) {
                      context.push(
                        Routes.expenseDetails.replaceAll(':id', exp.id),
                        extra: exp,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // 6. Primary Add Expense Action
      floatingActionButton: Semantics(
        button: true,
        label: 'Add Expense',
        child: BouncingButton(
          scale: 0.94,
          onTap: () => context.push(Routes.addExpense),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: CoSpendColors.jadeGreen,
              borderRadius: CoSpendRadii.pillRadius,
              boxShadow: CoSpendShadows.floating,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. TOP HEADER COMPONENT
// =============================================================================

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.photoUrl,
    required this.greeting,
    required this.budgetStatus,
    required this.selectedMonth,
    required this.unreadNotifs,
    required this.inviteCode,
    required this.onPickMonth,
    required this.onNotificationTap,
    required this.onInviteTap,
    required this.onAvatarTap,
  });

  final String userName;
  final String? photoUrl;
  final String greeting;
  final BudgetStatus? budgetStatus;
  final DateTime selectedMonth;
  final int unreadNotifs;
  final String inviteCode;
  final VoidCallback onPickMonth;
  final VoidCallback onNotificationTap;
  final VoidCallback onInviteTap;
  final VoidCallback onAvatarTap;

  String _subtitle() {
    if (budgetStatus == null || budgetStatus!.budgetPaisa <= 0) {
      return 'Shared expense tracker';
    }
    if (budgetStatus!.isExceeded) {
      return 'Household is over budget this month';
    }
    if (budgetStatus!.isApproaching) {
      return 'Household is approaching budget limit';
    }
    return 'Your household is on track this month';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper row: Avatar + Greeting + Notifications & Invite chip
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar with Jade Border Ring
            Semantics(
              label: 'View profile for $userName',
              button: true,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CoSpendColors.jadeGreen.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: AppAvatar(
                    name: userName,
                    photoUrl: photoUrl,
                    size: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Greeting & Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Notification Button with Unread Badge
            Semantics(
              label: 'Notifications, $unreadNotifs unread',
              button: true,
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Badge(
                  isLabelVisible: unreadNotifs > 0,
                  backgroundColor: CoSpendColors.alertRed,
                  textColor: Colors.white,
                  label: Text('$unreadNotifs'),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    size: 24,
                  ),
                ),
                tooltip: 'Notifications',
                onPressed: onNotificationTap,
              ),
            ),

            // Household Invite Chip
            Semantics(
              label: 'Invite code $inviteCode',
              button: true,
              child: InkWell(
                onTap: onInviteTap,
                borderRadius: CoSpendRadii.pillRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CoSpendColors.darkCard
                        : CoSpendColors.jadeGreenTint,
                    borderRadius: CoSpendRadii.pillRadius,
                    border: Border.all(
                      color: isDark
                          ? CoSpendColors.darkBorder
                          : CoSpendColors.jadeGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group_add_rounded,
                        size: 14,
                        color: CoSpendColors.jadeGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: CoSpendColors.jadeGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Subtitle & Interactive Month Selector Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _subtitle(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Month Picker Pill
            Semantics(
              button: true,
              label: 'Select month, currently ${DateFormat('MMMM yyyy').format(selectedMonth)}',
              child: InkWell(
                onTap: onPickMonth,
                borderRadius: CoSpendRadii.pillRadius,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CoSpendColors.darkCard
                        : CoSpendColors.surfaceMuted,
                    borderRadius: CoSpendRadii.pillRadius,
                    border: Border.all(
                      color: isDark
                          ? CoSpendColors.darkBorder
                          : CoSpendColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMM yyyy').format(selectedMonth),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// 2. FINANCIAL HERO CARD
// =============================================================================

class _FinancialHeroCard extends StatelessWidget {
  const _FinancialHeroCard({
    required this.budgetStatus,
    required this.totalBudgetPaisa,
    required this.isOwner,
    required this.onConfigureBudget,
  });

  final BudgetStatus? budgetStatus;
  final int totalBudgetPaisa;
  final bool isOwner;
  final VoidCallback onConfigureBudget;

  Color _progressColor(double pct, bool isExceeded) {
    if (isExceeded || pct >= 100.0) return CoSpendColors.alertRed;
    if (pct >= 80.0) return CoSpendColors.warningAmber;
    return CoSpendColors.jadeGreen;
  }

  @override
  Widget build(BuildContext context) {
    // If no total budget is configured, show a high-conversion setup card
    if (budgetStatus == null || totalBudgetPaisa <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: CoSpendRadii.cardRadius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A2542),
              Color(0xFF10355D),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: CoSpendColors.prussianBlue.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.savings_rounded,
                color: CoSpendColors.jadeGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Monthly Budget Set',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isOwner
                        ? 'Set a spending target to align your household.'
                        : 'Spending limits set by flat owner.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onConfigureBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoSpendColors.jadeGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: CoSpendRadii.mediumRadius,
                ),
              ),
              child: Text(isOwner ? 'Set Target' : 'View'),
            ),
          ],
        ),
      );
    }

    final status = budgetStatus!;
    final pct = status.percentage.clamp(0.0, 100.0);
    final isExceeded = status.isExceeded;
    final isApproaching = status.isApproaching;
    final progressColor = _progressColor(status.percentage, isExceeded);

    final statusBadgeText = isExceeded
        ? 'EXCEEDED'
        : isApproaching
            ? 'APPROACHING'
            : 'ON TRACK';

    final statusBadgeBg = isExceeded
        ? CoSpendColors.alertRed.withValues(alpha: 0.2)
        : isApproaching
            ? CoSpendColors.warningAmber.withValues(alpha: 0.2)
            : CoSpendColors.jadeGreen.withValues(alpha: 0.2);

    final statusBadgeColor = isExceeded
        ? const Color(0xFFFF8B8B)
        : isApproaching
            ? const Color(0xFFFFD480)
            : CoSpendColors.jadeGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: CoSpendRadii.cardRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2542),
            Color(0xFF0E3259),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CoSpendColors.prussianBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag Row: "MONTHLY BUDGET" + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 15,
                        color: CoSpendColors.jadeGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'MONTHLY BUDGET',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: CoSpendRadii.pillRadius,
                ),
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    color: statusBadgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Spent Amount Display
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                Money.format(status.spentPaisa),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              Text(
                'spent of ${Money.format(status.budgetPaisa)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: CoSpendRadii.pillRadius,
            child: Container(
              height: 7,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.12),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: CoSpendAnimations.medium,
                curve: CoSpendAnimations.curveDefault,
                widthFactor: pct / 100.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: CoSpendRadii.pillRadius,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Secondary Comparison Row: Percentage Used + Remaining Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${status.percentage.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isExceeded
                      ? '${Money.format(-status.remainingPaisa)} over budget'
                      : '${Money.format(status.remainingPaisa)} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isExceeded
                        ? const Color(0xFFFF8B8B)
                        : CoSpendColors.jadeGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
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
// 3. FOUR FINANCIAL METRICS
// =============================================================================

class _FourFinancialMetrics extends StatelessWidget {
  const _FourFinancialMetrics({
    required this.totalBudgetPaisa,
    required this.totalSpendingPaisa,
    required this.userAllocatedSharePaisa,
    required this.userSpentPaisa,
    required this.isDark,
  });

  final int totalBudgetPaisa;
  final int totalSpendingPaisa;
  final int userAllocatedSharePaisa;
  final int userSpentPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isFlatOver =
        totalBudgetPaisa > 0 && totalSpendingPaisa > totalBudgetPaisa;
    final isUserOver =
        userAllocatedSharePaisa > 0 && userSpentPaisa > userAllocatedSharePaisa;
    final userRemainingPaisa = userAllocatedSharePaisa - userSpentPaisa;

    return Column(
      children: [
        // Row 1: Total Allocated Budget & Total Spendings
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'TOTAL BUDGET',
                amount: totalBudgetPaisa > 0
                    ? Money.format(totalBudgetPaisa)
                    : 'Not set',
                icon: Icons.savings_outlined,
                iconColor: CoSpendColors.jadeGreen,
                subtext: totalBudgetPaisa > 0
                    ? 'Household target'
                    : 'Set monthly goal',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'TOTAL SPENDINGS',
                amount: Money.format(totalSpendingPaisa),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: isFlatOver
                    ? CoSpendColors.alertRed
                    : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                subtext: 'Across all flatmates',
                isWarning: isFlatOver,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Your Allocated Share & Your Spending
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'YOUR SHARE',
                amount: userAllocatedSharePaisa > 0
                    ? Money.format(userAllocatedSharePaisa)
                    : 'Unset',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: isDark ? Colors.white : CoSpendColors.prussianBlue,
                subtext: 'Your allocated quota',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'YOUR SPENDING',
                amount: Money.format(userSpentPaisa),
                icon: Icons.person_outline_rounded,
                iconColor: isUserOver
                    ? CoSpendColors.alertRed
                    : CoSpendColors.jadeGreen,
                subtext: userAllocatedSharePaisa > 0
                    ? (isUserOver
                        ? '${Money.format(-userRemainingPaisa)} over'
                        : '${Money.format(userRemainingPaisa)} remaining')
                    : 'Total paid by you',
                isWarning: isUserOver,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.subtext,
    required this.isDark,
    this.isWarning = false,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final String subtext;
  final bool isDark;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isWarning
              ? CoSpendColors.alertRed.withValues(alpha: 0.3)
              : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight),
          width: 1,
        ),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textMuted,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark ? Colors.white : CoSpendColors.prussianBlue),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textSubtle),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. BUDGET OVERVIEW (CATEGORIES)
// =============================================================================

class _BudgetOverviewSection extends StatelessWidget {
  const _BudgetOverviewSection({
    required this.categoryBudgets,
    required this.isOwner,
    required this.isDark,
    required this.onManage,
  });

  final List<CategoryBudgetStatus> categoryBudgets;
  final bool isOwner;
  final bool isDark;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            TextButton(
              onPressed: onManage,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: CoSpendColors.jadeGreen,
              ),
              child: Text(
                isOwner ? 'Manage' : 'View all',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Categories List or Empty State
        if (categoryBudgets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
              borderRadius: CoSpendRadii.cardRadius,
              border: Border.all(
                color: isDark
                    ? CoSpendColors.darkBorder
                    : CoSpendColors.borderLight,
              ),
              boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.pie_chart_outline_rounded,
                    color: CoSpendColors.jadeGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No category limits set',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOwner
                            ? 'Set category limits for Food, Bills, etc.'
                            : 'Spending limits set by flat owner.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onManage,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: CoSpendColors.jadeGreen,
                    side: const BorderSide(
                        color: CoSpendColors.jadeGreen, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isOwner ? 'Set Limits' : 'View'),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (final cat in categoryBudgets.take(4))
                _CategoryBudgetRow(cat: cat, isDark: isDark),
            ],
          ),
      ],
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  const _CategoryBudgetRow({
    required this.cat,
    required this.isDark,
  });

  final CategoryBudgetStatus cat;
  final bool isDark;

  Color _progressColor(double pct, bool isExceeded) {
    if (isExceeded || pct >= 100.0) return CoSpendColors.alertRed;
    if (pct >= 85.0) return CoSpendColors.warningAmber;
    return CoSpendColors.jadeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final pct = cat.percentage.clamp(0.0, 100.0);
    final color = _progressColor(cat.percentage, cat.isExceeded);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
        ),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tinted Category Icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(cat.icon, size: 18, color: cat.color),
              ),
              const SizedBox(width: 10),

              // Category Name
              Expanded(
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Spent of Limit
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(cat.spentPaisa),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cat.isExceeded
                          ? CoSpendColors.alertRed
                          : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                    ),
                  ),
                  Text(
                    'of ${Money.format(cat.budgetPaisa)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: CoSpendRadii.pillRadius,
                ),
                child: Text(
                  '${cat.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Micro Progress Bar
          ClipRRect(
            borderRadius: CoSpendRadii.pillRadius,
            child: Container(
              height: 4.5,
              width: double.infinity,
              color: isDark
                  ? CoSpendColors.darkBorder
                  : const Color(0xFFF1F5F9),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: CoSpendAnimations.fast,
                curve: CoSpendAnimations.curveDefault,
                widthFactor: pct / 100.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: CoSpendRadii.pillRadius,
                  ),
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
// 5. RECENT ACTIVITY COMPONENT
// =============================================================================

class _RecentExpensesSection extends StatelessWidget {
  const _RecentExpensesSection({
    required this.recentExpensesAsync,
    required this.memberNameMap,
    required this.isDark,
    required this.onViewAll,
    required this.onExpenseTap,
  });

  final AsyncValue<List<dynamic>> recentExpensesAsync;
  final Map<String, String> memberNameMap;
  final bool isDark;
  final VoidCallback onViewAll;
  final ValueChanged<dynamic> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: CoSpendColors.jadeGreen,
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        recentExpensesAsync.when(
          loading: () => const Column(
            children: [
              SkeletonBox(height: 60),
              SizedBox(height: 8),
              SkeletonBox(height: 60),
            ],
          ),
          error: (error, _) => Text(
            FirebaseErrorMapper.messageFor(error),
            style: const TextStyle(color: CoSpendColors.alertRed),
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
                  ),
                  boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 32,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textSubtle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color:
                            isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Expense" below to start sharing costs.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final exp in recent)
                  _ExpenseItemTile(
                    description: exp.description,
                    amountPaisa: exp.amountPaisa,
                    category: exp.category,
                    customCategoryId: exp.customCategoryId,
                    subcategory: exp.subcategory,
                    spentAt: exp.spentAt,
                    payerName: memberNameMap[exp.paidById] ?? 'Flatmate',
                    isDark: isDark,
                    onTap: () => onExpenseTap(exp),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExpenseItemTile extends ConsumerWidget {
  const _ExpenseItemTile({
    required this.description,
    required this.amountPaisa,
    required this.category,
    this.customCategoryId,
    this.subcategory,
    required this.spentAt,
    required this.payerName,
    required this.isDark,
    required this.onTap,
  });

  final String description;
  final int amountPaisa;
  final dynamic category;
  final String? customCategoryId;
  final String? subcategory;
  final DateTime spentAt;
  final String payerName;
  final bool isDark;
  final VoidCallback onTap;

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(date);
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
    final hasSubcat = subcategory != null && subcategory!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BouncingButton(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color:
                  isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            ),
            boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
          ),
          child: Row(
            children: [
              // Tinted Category Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Description and Payer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color:
                            isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Paid by $payerName · ${_relativeDate(spentAt)}',
                          style: TextStyle(
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                        if (hasSubcat) ...[
                          Text(
                            ' · $subcategory',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textSubtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount
              Text(
                Money.format(amountPaisa),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ALERT BANNER FOR EXCEEDED BUDGETS
// =============================================================================

class _BudgetAlertBanner extends StatelessWidget {
  const _BudgetAlertBanner({
    required this.alert,
    required this.isDark,
  });

  final dynamic alert;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1015) : const Color(0xFFFFF5F5),
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: CoSpendColors.alertRed.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: CoSpendColors.alertRed,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(CoSpendRadii.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CoSpendColors.alertRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: CoSpendColors.alertRed,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${alert.label} Budget Exceeded',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: CoSpendColors.alertRed,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You spent ${Money.format(alert.mySpentPaisa)} of your ${Money.format(alert.myBudgetPaisa)} quota for this month.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LOADING SKELETON
// =============================================================================

class _HomeScreenSkeleton extends StatelessWidget {
  const _HomeScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        // Header Skeleton
        Row(
          children: [
            SkeletonBox(height: 44, width: 44, radius: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 100),
                  SizedBox(height: 6),
                  SkeletonBox(height: 20, width: 160),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Hero Card Skeleton
        SkeletonBox(height: 160, radius: 16),
        SizedBox(height: 18),

        // 4 Metrics Skeleton
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 80, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 80, radius: 16)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 80, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 80, radius: 16)),
          ],
        ),
        SizedBox(height: 24),

        // Overview Skeleton
        SkeletonBox(height: 20, width: 140),
        SizedBox(height: 12),
        SkeletonBox(height: 70, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 70, radius: 16),
      ],
    );
  }
}