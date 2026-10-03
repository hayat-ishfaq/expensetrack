import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
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
import '../widgets/home_budget_alert_banner.dart';
import '../widgets/home_hero_spend_card.dart';
import '../widgets/home_quick_insights_row.dart';
import '../widgets/home_recent_activity_tile.dart';
import '../widgets/home_stats_grid.dart';

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
              // â”€â”€ Greeting + Month Selector + Invite Code â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

              // â”€â”€ Hero Total Monthly Spend Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              HomeHeroSpendCard(
                totalSpendingPaisa: stats.totalSpendingPaisa,
                budgetPaisa: household.effectiveTotalBudgetPaisa,
                sharedSpendingPaisa: stats.totalSpendingPaisa - stats.userPaidPaisa,
                individualSpendingPaisa: stats.userPaidPaisa,
                budgetStatus: budgetStatus,
              ),
              const SizedBox(height: 14),

              // â”€â”€ 2Ã—2 Stats Grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              HomeStatsGrid(
                totalBudgetPaisa: household.effectiveTotalBudgetPaisa,
                totalSpendingPaisa: stats.totalSpendingPaisa,
                userSharePaisa: stats.userSharePaisa,
                userPaidPaisa: stats.userPaidPaisa,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // â”€â”€ Budget Alerts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (exceededAlerts.isNotEmpty) ...[
                for (final alert in exceededAlerts)
                  HomeBudgetAlertBanner(
                    label: alert.label,
                    mySpentPaisa: alert.mySpentPaisa,
                    myBudgetPaisa: alert.myBudgetPaisa,
                    isDark: isDark,
                  ),
              ],

              // â”€â”€ Recent Activity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                            HomeRecentActivityTile(
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

              // â”€â”€ Quick Insights â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              HomeQuickInsightsRow(
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Header Section Widget
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
