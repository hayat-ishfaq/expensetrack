import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/budget_progress_card.dart';
import '../../../dashboard/presentation/widgets/category_breakdown_card.dart';
import '../../../dashboard/presentation/widgets/financial_card.dart';
import '../../../dashboard/presentation/widgets/spending_chart.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/widgets/invite_members_sheet.dart';

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
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final recentExpensesAsync = ref.watch(recentExpensesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final budgetStatus = ref.watch(budgetStatusProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final exceededAlerts = ref.watch(exceededBudgetAlertsProvider);

    final userName = session?.user?.name.split(' ').first ?? 'Roommate';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting()}, $userName 👋',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () => _pickMonth(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          householdAsync.maybeWhen(
            data: (household) => household != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ActionChip(
                      avatar: const Icon(Icons.group_add_rounded, size: 15),
                      label: Text(
                        'Invite (${household.inviteCode})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () =>
                          InviteMembersSheet.show(context, household),
                    ),
                  )
                : const SizedBox.shrink(),
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

          final currentUserId = session?.user?.id ?? '';
          final isOwner =
              household.ownerId.isEmpty || household.ownerId == currentUserId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Personal Category Budget Alerts
              if (exceededAlerts.isNotEmpty) ...[
                for (final alert in exceededAlerts)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${alert.label} Budget Exceeded!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You spent your whole ${alert.label.toLowerCase()} budget for this month (${Money.format(alert.mySpentPaisa)} spent of ${Money.format(alert.myBudgetPaisa)} limit).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // 4 Financial Summary Cards
              FinancialSummaryCards(stats: stats),
              const SizedBox(height: 16),

              // Monthly Budget Card
              if (budgetStatus != null) ...[
                BudgetProgressCard(budgetStatus: budgetStatus),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.savings_rounded, color: scheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOwner
                                  ? 'Set Category Budgets'
                                  : 'Category Budgets',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isOwner
                                  ? 'Track spending caps for Food, Bills, etc.'
                                  : 'Spending limits set by flat owner.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push(Routes.categoryBudgets),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(isOwner ? 'Set' : 'View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Daily Spending Trend Bar Chart
              MonthlySpendingChart(
                stats: stats,
                selectedMonth: selectedMonth,
              ),
              const SizedBox(height: 16),

              // Category Breakdown Card (if any spending exists)
              if (stats.categoryBreakdown.isNotEmpty) ...[
                CategoryBreakdownCard(stats: stats),
                const SizedBox(height: 16),
              ],

              // Recent Expenses Header + List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT EXPENSES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.expenses),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

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
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
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
                            'Tap the button below to add your first expense.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final exp in recent)
                        _RecentExpenseTile(
                          description: exp.description,
                          amountPaisa: exp.amountPaisa,
                          category: exp.category,
                          customCategoryId: exp.customCategoryId,
                          subcategory: exp.subcategory,
                          spentAt: exp.spentAt,
                          payerName:
                              memberNameMap[exp.paidById] ?? 'Flatmate',
                          onTap: () {
                            context.push(
                              Routes.expenseDetails.replaceAll(':id', exp.id),
                              extra: exp,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addExpense),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _RecentExpenseTile extends ConsumerWidget {
  const _RecentExpenseTile({
    required this.description,
    required this.amountPaisa,
    required this.category,
    this.customCategoryId,
    this.subcategory,
    required this.spentAt,
    required this.payerName,
    required this.onTap,
  });

  final String description;
  final int amountPaisa;
  final dynamic category;
  final String? customCategoryId;
  final String? subcategory;
  final DateTime spentAt;
  final String payerName;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == customCategoryId)
            .firstOrNull
        : null;
    final catColor = custom?.color ?? category.color as Color;
    final catIcon = custom?.icon ?? category.icon as IconData;
    final hasSubcat = subcategory != null && subcategory!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Paid by $payerName · ${_relativeDate(spentAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (hasSubcat) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subcategory!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Money.format(amountPaisa),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 90)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 90)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 90)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 90)),
          ],
        ),
        SizedBox(height: 20),
        SkeletonBox(height: 160),
        SizedBox(height: 20),
        SkeletonBox(height: 120),
      ],
    );
  }
}