import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../expenses/domain/expense.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';

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
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return e.spentAt.isAfter(start.subtract(const Duration(seconds: 1)));
        case DateFilter.thisMonth:
          return e.spentAt.year == now.year && e.spentAt.month == now.month;
      }
    }).toList();
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Expense>>{};

    for (final exp in expenses) {
      final expDate = DateTime(exp.spentAt.year, exp.spentAt.month, exp.spentAt.day);
      String groupKey;
      if (expDate == today) {
        groupKey = 'TODAY · ${DateFormat('dd MMMM').format(exp.spentAt)}';
      } else if (expDate == yesterday) {
        groupKey = 'YESTERDAY · ${DateFormat('dd MMMM').format(exp.spentAt)}';
      } else {
        groupKey = DateFormat('dd MMMM yyyy').format(exp.spentAt).toUpperCase();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
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
                      message: "Your household hasn't recorded any expenses yet.",
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

          return Column(
            children: [
              // Search Bar: Soft pill with subtle shadow
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                    borderRadius: CoSpendRadii.pillRadius,
                    boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
                    border: Border.all(
                      color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
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
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Filter Chips: Solid Prussian Blue when active, thin border when inactive
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterPill(
                      label: 'All',
                      isSelected: _dateFilter == DateFilter.all && _categoryFilter == null,
                      onTap: () {
                        setState(() {
                          _dateFilter = DateFilter.all;
                          _categoryFilter = null;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'Today',
                      isSelected: _dateFilter == DateFilter.today,
                      onTap: () {
                        setState(() {
                          _dateFilter = _dateFilter == DateFilter.today
                              ? DateFilter.all
                              : DateFilter.today;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'This week',
                      isSelected: _dateFilter == DateFilter.thisWeek,
                      onTap: () {
                        setState(() {
                          _dateFilter = _dateFilter == DateFilter.thisWeek
                              ? DateFilter.all
                              : DateFilter.thisWeek;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'This month',
                      isSelected: _dateFilter == DateFilter.thisMonth,
                      onTap: () {
                        setState(() {
                          _dateFilter = _dateFilter == DateFilter.thisMonth
                              ? DateFilter.all
                              : DateFilter.thisMonth;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),

                    // Category Filter Dropdown Pill
                    GestureDetector(
                      onTap: () => _pickCategorySheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _categoryFilter != null
                              ? CoSpendColors.prussianBlue
                              : (isDark ? CoSpendColors.darkCard : CoSpendColors.white),
                          borderRadius: CoSpendRadii.pillRadius,
                          border: Border.all(
                            color: _categoryFilter != null
                                ? CoSpendColors.prussianBlue
                                : (isDark ? CoSpendColors.darkBorder : CoSpendColors.border),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryFilter?.icon ?? Icons.tune_rounded,
                              size: 15,
                              color: _categoryFilter != null
                                  ? Colors.white
                                  : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _categoryFilter?.label ?? 'Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _categoryFilter != null ? FontWeight.w700 : FontWeight.w500,
                                color: _categoryFilter != null
                                    ? Colors.white
                                    : (isDark ? Colors.white : CoSpendColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Divider(
                height: 1,
                color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
              ),

              // Expense List or Empty Search
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateHeader = grouped.keys.elementAt(groupIndex);
                          final items = grouped[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(dateHeader),
                              for (final exp in items)
                                _ExpenseTile(
                                  expense: exp,
                                  payerName: memberNameMap[exp.paidById] ?? 'Flatmate',
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
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          boxShadow: CoSpendShadows.floating,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.addExpense),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Add Expense',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
          backgroundColor: CoSpendColors.jadeGreen,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CoSpendColors.prussianBlue
              : (isDark ? CoSpendColors.darkCard : Colors.transparent),
          borderRadius: CoSpendRadii.pillRadius,
          border: Border.all(
            color: isSelected
                ? CoSpendColors.prussianBlue
                : (isDark ? CoSpendColors.darkBorder : CoSpendColors.border),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
          ),
        ),
      ),
    );
  }

  void _pickCategorySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Category',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      if (_categoryFilter != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _categoryFilter = null);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final cat in ExpenseCategory.values)
                        ListTile(
                          leading: TintedIcon(
                            icon: cat.icon,
                            color: CoSpendColors.prussianBlue,
                            size: 19,
                            containerSize: 38,
                          ),
                          title: Text(
                            cat.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : CoSpendColors.textPrimary,
                            ),
                          ),
                          trailing: _categoryFilter == cat
                              ? const Icon(Icons.check_circle_rounded, color: CoSpendColors.jadeGreen)
                              : null,
                          onTap: () {
                            setState(() => _categoryFilter = cat);
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({
    required this.expense,
    required this.payerName,
    required this.onTap,
  });

  final Expense expense;
  final String payerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = expense.customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == expense.customCategoryId)
            .firstOrNull
        : null;
    final catIcon = custom?.icon ?? expense.category.icon;
    final catLabel = custom?.label ?? expense.category.label;
    final dateStr = DateFormat('dd MMM').format(expense.spentAt);
    final hasSubcat =
        expense.subcategory != null && expense.subcategory!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CoSpendCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            TintedIcon(
              icon: catIcon,
              color: CoSpendColors.prussianBlue,
              size: 20,
              containerSize: 42,
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Paid by $payerName · $dateStr',
                        style: TextStyle(
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      if (hasSubcat) ...[
                        Text(
                          ' · ${expense.subcategory}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(expense.amountPaisa),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  catLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? CoSpendColors.darkBorder : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesSkeleton extends StatelessWidget {
  const _ExpensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 48),
        SizedBox(height: 16),
        SkeletonBox(height: 64),
        SizedBox(height: 8),
        SkeletonBox(height: 64),
        SizedBox(height: 8),
        SkeletonBox(height: 64),
      ],
    );
  }
}