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
      // Query filter
      if (query.isNotEmpty &&
          !e.description.toLowerCase().contains(query)) {
        return false;
      }

      // Category filter
      if (_categoryFilter != null && e.category != _categoryFilter) {
        return false;
      }

      // Date filter
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expensesAsync = ref.watch(householdExpensesProvider);
    final membersAsync = ref.watch(householdMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
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

          return Column(
            children: [
              // Search Bar & Filter Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _dateFilter == DateFilter.all &&
                          _categoryFilter == null,
                      onSelected: (_) {
                        setState(() {
                          _dateFilter = DateFilter.all;
                          _categoryFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Today'),
                      selected: _dateFilter == DateFilter.today,
                      onSelected: (selected) {
                        setState(() {
                          _dateFilter =
                              selected ? DateFilter.today : DateFilter.all;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This week'),
                      selected: _dateFilter == DateFilter.thisWeek,
                      onSelected: (selected) {
                        setState(() {
                          _dateFilter =
                              selected ? DateFilter.thisWeek : DateFilter.all;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This month'),
                      selected: _dateFilter == DateFilter.thisMonth,
                      onSelected: (selected) {
                        setState(() {
                          _dateFilter =
                              selected ? DateFilter.thisMonth : DateFilter.all;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Category Filter Dropdown Chip
                    ActionChip(
                      avatar: _categoryFilter != null
                          ? Icon(
                              _categoryFilter!.icon,
                              size: 16,
                              color: _categoryFilter!.color,
                            )
                          : const Icon(Icons.tune_rounded, size: 16),
                      label: Text(
                        _categoryFilter?.label ?? 'Category',
                        style: TextStyle(
                          color: _categoryFilter != null
                              ? scheme.primary
                              : scheme.onSurface,
                          fontWeight: _categoryFilter != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _pickCategorySheet(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Expense List or Empty Search
              Expanded(
                child: filteredExpenses.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No expenses found',
                          message:
                              'Try changing your search keywords or clearing active filters.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateHeader =
                              grouped.keys.elementAt(groupIndex);
                          final items = grouped[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 8,
                                  left: 4,
                                ),
                                child: Text(
                                  dateHeader,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              for (final exp in items)
                                _ExpenseTile(
                                  expense: exp,
                                  payerName:
                                      memberNameMap[exp.paidById] ?? 'Flatmate',
                                  onTap: () {
                                    context.push(
                                      Routes.expenseDetails
                                          .replaceAll(':id', exp.id),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addExpense),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  void _pickCategorySheet(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 20),
                          ),
                          title: Text(
                            cat.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: _categoryFilter == cat
                              ? const Icon(Icons.check_circle_rounded)
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = expense.customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == expense.customCategoryId)
            .firstOrNull
        : null;
    final catColor = custom?.color ?? expense.category.color;
    final catIcon = custom?.icon ?? expense.category.icon;
    final catLabel = custom?.label ?? expense.category.label;
    final dateStr = DateFormat('dd MMM').format(expense.spentAt);
    final hasSubcat =
        expense.subcategory != null && expense.subcategory!.trim().isNotEmpty;

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Paid by $payerName · $dateStr',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
                              expense.subcategory!,
                              style: TextStyle(
                                fontSize: 10,
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(expense.amountPaisa),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      catLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.outline,
              ),
            ],
          ),
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
        SizedBox(height: 12),
        SkeletonBox(height: 36),
        SizedBox(height: 16),
        SkeletonBox(height: 72),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
        SizedBox(height: 8),
        SkeletonBox(height: 72),
      ],
    );
  }
}