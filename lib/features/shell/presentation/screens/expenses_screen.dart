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
import '../../../expenses/domain/expense.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../household/presentation/widgets/notification_bell_button.dart';

enum DateFilter { all, today, thisWeek, thisMonth }

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  DateFilter _dateFilter = DateFilter.all;
  ExpenseCategory? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return expenses.where((e) {
      if (query.isNotEmpty && !e.description.toLowerCase().contains(query)) {
        return false;
      }
      if (_categoryFilter != null && e.category != _categoryFilter) {
        return false;
      }
      switch (_dateFilter) {
        case DateFilter.all:
          return true;
        case DateFilter.today:
          return e.spentAt.year == now.year &&
              e.spentAt.month == now.month &&
              e.spentAt.day == now.day;
        case DateFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          return e.spentAt.isAfter(start.subtract(const Duration(seconds: 1)));
        case DateFilter.thisMonth:
          return e.spentAt.year == now.year && e.spentAt.month == now.month;
      }
    }).toList();
  }

  /// Groups expenses by date, returning an ordered map of label → items.
  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Expense>>{};

    for (final exp in expenses) {
      final expDate = DateTime(
        exp.spentAt.year,
        exp.spentAt.month,
        exp.spentAt.day,
      );
      String groupKey;
      if (expDate == today) {
        groupKey = 'TODAY';
      } else if (expDate == yesterday) {
        groupKey = 'YESTERDAY';
      } else {
        groupKey = DateFormat('MMMM dd, yyyy')
            .format(exp.spentAt)
            .toUpperCase();
      }
      groups.putIfAbsent(groupKey, () => []).add(exp);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(householdExpensesProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final session = ref.watch(sessionProvider).value;
    final currentUser = ref.watch(currentUserProvider).value ?? session?.user;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark
            ? CoSpendColors.darkCanvas
            : CoSpendColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Expenses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
        actions: [
          const NotificationBellButton(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CoSpendColors.jadeGreen, width: 2),
                ),
                child: AppAvatar(
                  name: currentUser?.name ?? 'User',
                  photoUrl: currentUser?.photoUrl,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const _ExpensesSkeleton(),
        error: (error, _) => ErrorView(
          message: error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          onRetry: () => ref.invalidate(householdExpensesProvider),
        ),
        data: (allExpenses) {
          if (allExpenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses yet',
                      message:
                          "Your household hasn't recorded any expenses yet.",
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push(Routes.addExpense),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add your first expense'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredExpenses = _filterExpenses(allExpenses);
          final grouped = _groupByDate(filteredExpenses);

          final members = membersAsync.value ?? const [];
          final memberNameMap = {for (final m in members) m.id: m.name};

          // Build category chips from available categories in this data
          final availableCategories = allExpenses
              .map((e) => e.category)
              .toSet()
              .toList();

          return Column(
            children: [
              // ── Search Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? CoSpendColors.darkCard
                        : CoSpendColors.white,
                    borderRadius: CoSpendRadii.pillRadius,
                    border: Border.all(
                      color: isDark
                          ? CoSpendColors.darkBorder
                          : CoSpendColors.borderLight,
                      width: 1,
                    ),
                    boxShadow: isDark ? null : CoSpendShadows.cardSubtle,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textSubtle,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // ── Category Filter Chips ───────────────────────────────────
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // "All" chip
                    _CategoryChip(
                      label: 'All',
                      icon: Icons.receipt_long_rounded,
                      isSelected:
                          _categoryFilter == null &&
                          _dateFilter == DateFilter.all,
                      onTap: () => setState(() {
                        _categoryFilter = null;
                        _dateFilter = DateFilter.all;
                      }),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    // Category-specific chips
                    for (final cat in availableCategories) ...[
                      _CategoryChip(
                        label: cat.label,
                        icon: cat.icon,
                        isSelected: _categoryFilter == cat,
                        onTap: () => setState(() {
                          _categoryFilter = _categoryFilter == cat ? null : cat;
                          _dateFilter = DateFilter.all;
                        }),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // ── Expense List ────────────────────────────────────────────
              Expanded(
                child: filteredExpenses.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No expenses found',
                          message: 'Try changing your search keywords or clearing active filters.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                        itemCount: grouped.keys.length + 1, // +1 for footer
                        itemBuilder: (context, groupIndex) {
                          // Footer
                          if (groupIndex == grouped.keys.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Showing all records',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? CoSpendColors.darkTextMuted
                                      : CoSpendColors.textSubtle,
                                ),
                              ),
                            );
                          }

                          final dateHeader = grouped.keys.elementAt(groupIndex);
                          final items = grouped[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateHeader,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isDark
                                            ? CoSpendColors.darkTextMuted
                                            : CoSpendColors.textMuted,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? CoSpendColors.darkCard
                                            : CoSpendColors.white,
                                        borderRadius: CoSpendRadii.pillRadius,
                                        border: Border.all(
                                          color: isDark
                                              ? CoSpendColors.darkBorder
                                              : CoSpendColors.borderLight,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        '${items.length} ${items.length == 1 ? 'Entry' : 'Entries'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? CoSpendColors.darkTextMuted
                                              : CoSpendColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Expense Tiles in a card group
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? CoSpendColors.darkCard
                                      : CoSpendColors.white,
                                  borderRadius: CoSpendRadii.cardRadius,
                                  border: Border.all(
                                    color: isDark
                                        ? CoSpendColors.darkBorder
                                        : CoSpendColors.borderLight,
                                    width: 0.8,
                                  ),
                                  boxShadow: isDark
                                      ? null
                                      : CoSpendShadows.card,
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < items.length; i++) ...[
                                      _LedgerExpenseTile(
                                        expense: items[i],
                                        payerName:
                                            memberNameMap[items[i].paidById] ??
                                            'Flatmate',
                                        currentUserId: currentUserId,
                                        onTap: () {
                                          context.push(
                                            Routes.expenseDetails.replaceAll(
                                              ':id',
                                              items[i].id,
                                            ),
                                            extra: items[i],
                                          );
                                        },
                                        isDark: isDark,
                                      ),
                                      if (i < items.length - 1)
                                        Divider(
                                          height: 1,
                                          color: isDark
                                              ? CoSpendColors.darkBorder
                                              : CoSpendColors.borderLight,
                                          indent: 72,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: CoSpendShadows.floating,
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(Routes.addExpense),
          backgroundColor: CoSpendColors.jadeGreen,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filter Chip
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CoSpendColors.jadeGreen
              : (isDark ? CoSpendColors.darkCard : CoSpendColors.white),
          borderRadius: CoSpendRadii.pillRadius,
          border: Border.all(
            color: isSelected
                ? CoSpendColors.jadeGreen
                : (isDark ? CoSpendColors.darkBorder : CoSpendColors.border),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CoSpendColors.jadeGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : CoSpendColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger Expense Tile
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerExpenseTile extends ConsumerWidget {
  const _LedgerExpenseTile({
    required this.expense,
    required this.payerName,
    required this.currentUserId,
    required this.onTap,
    required this.isDark,
  });

  final Expense expense;
  final String payerName;
  final String currentUserId;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = expense.customCategoryId != null
        ? household?.customCategories
              .where((c) => c.id == expense.customCategoryId)
              .firstOrNull
        : null;
    final catIcon = custom?.icon ?? expense.category.icon;
    final catLabel = custom?.label ?? expense.category.label;
    final catColor = custom?.color ?? expense.category.color;

    // Compute my share for "You get back / You owe" display
    final iPaid = expense.paidById == currentUserId;
    int mySharePaisa = 0;
    final myIndex = expense.splitAmongIds.indexOf(currentUserId);
    if (myIndex >= 0 && myIndex < expense.splitAmountsPaisa.length) {
      mySharePaisa = expense.splitAmountsPaisa[myIndex];
    }

    // If I paid: I get back (total - my share). If someone else paid: I owe my share.
    final int netPaisa;
    final bool isGetBack;
    if (iPaid) {
      netPaisa = expense.amountPaisa - mySharePaisa;
      isGetBack = true;
    } else {
      netPaisa = mySharePaisa;
      isGetBack = false;
    }

    final showSettleLine = netPaisa > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: CoSpendRadii.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Icon
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

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$catLabel · Paid by $payerName',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount + settle line
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(expense.amountPaisa),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
                if (showSettleLine) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGetBack
                            ? Icons.north_east_rounded
                            : Icons.south_west_rounded,
                        size: 12,
                        color: isGetBack
                            ? CoSpendColors.jadeGreen
                            : CoSpendColors.alertRed,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isGetBack
                            ? 'You get back ${Money.format(netPaisa)}'
                            : 'You owe ${Money.format(netPaisa)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isGetBack
                              ? CoSpendColors.jadeGreen
                              : CoSpendColors.alertRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensesSkeleton extends StatelessWidget {
  const _ExpensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 48),
        SizedBox(height: 12),
        SkeletonBox(height: 40),
        SizedBox(height: 20),
        SkeletonBox(height: 20),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
        SizedBox(height: 20),
        SkeletonBox(height: 20),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
      ],
    );
  }
}
