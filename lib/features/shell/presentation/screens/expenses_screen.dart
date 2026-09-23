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
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../expenses/domain/expense.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';

/// Predefined date grouping categories for financial activity timeline.
enum _TimelineGroup {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  earlier('Earlier');

  const _TimelineGroup(this.label);
  final String label;
}

/// Premium Financial Activity Timeline screen for CoSpend.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  ExpenseCategory? _categoryFilter;

  /// Tracks expense IDs that have already animated so normal Firestore updates
  /// do not re-trigger list animations.
  final Set<String> _animatedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters expenses by search query (description or payer) and category.
  List<Expense> _filterExpenses(
    List<Expense> expenses,
    Map<String, String> memberNameMap,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return expenses.where((e) {
      if (query.isNotEmpty) {
        final matchesDesc = e.description.toLowerCase().contains(query);
        final payerName = memberNameMap[e.paidById]?.toLowerCase() ?? '';
        final matchesPayer = payerName.contains(query);
        final subcat = e.subcategory?.toLowerCase() ?? '';
        final matchesSubcat = subcat.contains(query);
        if (!matchesDesc && !matchesPayer && !matchesSubcat) {
          return false;
        }
      }
      if (_categoryFilter != null && e.category != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Groups expenses into 4 discrete financial timeline tiers:
  /// Today, Yesterday, This Week, Earlier.
  Map<_TimelineGroup, List<Expense>> _groupByTimeline(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final groups = <_TimelineGroup, List<Expense>>{
      _TimelineGroup.today: [],
      _TimelineGroup.yesterday: [],
      _TimelineGroup.thisWeek: [],
      _TimelineGroup.earlier: [],
    };

    for (final exp in expenses) {
      final expDate =
          DateTime(exp.spentAt.year, exp.spentAt.month, exp.spentAt.day);

      if (expDate.isAtSameMomentAs(today)) {
        groups[_TimelineGroup.today]!.add(exp);
      } else if (expDate.isAtSameMomentAs(yesterday)) {
        groups[_TimelineGroup.yesterday]!.add(exp);
      } else if (expDate.isAfter(startOfWeek) ||
          expDate.isAtSameMomentAs(startOfWeek)) {
        groups[_TimelineGroup.thisWeek]!.add(exp);
      } else {
        groups[_TimelineGroup.earlier]!.add(exp);
      }
    }

    // Remove empty groups to keep the timeline crisp
    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final expensesAsync = ref.watch(householdExpensesProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final household = ref.watch(currentHouseholdProvider).value;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      body: SafeArea(
        bottom: false,
        child: expensesAsync.when(
          loading: () => const _ExpensesSkeleton(),
          error: (error, _) => ErrorView(
            message: error is AppException
                ? error.message
                : FirebaseErrorMapper.messageFor(error),
            onRetry: () => ref.invalidate(householdExpensesProvider),
          ),
          data: (allExpenses) {
            // Overall empty state (no expenses in household)
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
                      const SizedBox(height: 18),
                      BouncingButton(
                        scale: 0.95,
                        onTap: () => context.push(Routes.addExpense),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: CoSpendColors.jadeGreen,
                            borderRadius: CoSpendRadii.pillRadius,
                            boxShadow: CoSpendShadows.floating,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add your first expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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

            final members = membersAsync.value ?? const [];
            final memberNameMap = {for (final m in members) m.id: m.name};

            final filteredExpenses =
                _filterExpenses(allExpenses, memberNameMap);
            final timelineGroups = _groupByTimeline(filteredExpenses);

            return RefreshIndicator(
              color: CoSpendColors.jadeGreen,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.invalidate(householdExpensesProvider);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Title Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
                          ),
                        ),
                        // Total count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? CoSpendColors.darkCard
                                : CoSpendColors.surfaceMuted,
                            borderRadius: CoSpendRadii.pillRadius,
                            border: Border.all(
                              color: isDark
                                  ? CoSpendColors.darkBorder
                                  : CoSpendColors.borderLight,
                            ),
                          ),
                          child: Text(
                            '${allExpenses.length} total',
                            style: TextStyle(
                              fontSize: 11.5,
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

                  // 2. Premium Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? CoSpendColors.darkCard
                            : CoSpendColors.white,
                        borderRadius: CoSpendRadii.cardRadius,
                        border: Border.all(
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : CoSpendColors.borderLight,
                        ),
                        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : CoSpendColors.prussianBlue,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search expenses, roommates, categories...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
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
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Animated Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _categoryFilter == null,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _categoryFilter = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final cat in ExpenseCategory.values) ...[
                          _FilterChip(
                            label: cat.label,
                            icon: cat.icon,
                            isSelected: _categoryFilter == cat,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _categoryFilter =
                                    _categoryFilter == cat ? null : cat;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Divider(
                    height: 1,
                    color: isDark
                        ? CoSpendColors.darkBorder
                        : CoSpendColors.borderLight,
                  ),

                  // 4. Activity Timeline
                  Expanded(
                    child: filteredExpenses.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: isDark
                                        ? CoSpendColors.darkTextMuted
                                        : CoSpendColors.textSubtle,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No expenses found',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : CoSpendColors.prussianBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try changing keywords or clearing category filter.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? CoSpendColors.darkTextMuted
                                          : CoSpendColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      _searchController.clear();
                                      setState(() => _categoryFilter = null);
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                            itemCount: timelineGroups.keys.length,
                            itemBuilder: (context, groupIndex) {
                              final group =
                                  timelineGroups.keys.elementAt(groupIndex);
                              final items = timelineGroups[group]!;
                              final groupTotalPaisa = items.fold<int>(
                                0,
                                (sum, item) => sum + item.amountPaisa,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline Group Header
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 10, 4, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          group.label.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: isDark
                                                ? CoSpendColors.darkTextMuted
                                                : CoSpendColors.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${items.length} · ${Money.format(groupTotalPaisa)}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.7)
                                                : CoSpendColors.prussianBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Expense Tiles
                                  for (final exp in items)
                                    _TimelineExpenseTile(
                                      key: ValueKey(exp.id),
                                      expense: exp,
                                      payerName: memberNameMap[exp.paidById] ??
                                          'Flatmate',
                                      household: household,
                                      isDark: isDark,
                                      shouldAnimate:
                                          !_animatedIds.contains(exp.id),
                                      onAnimated: () =>
                                          _animatedIds.add(exp.id),
                                      onTap: () {
                                        context.push(
                                          Routes.expenseDetails
                                              .replaceAll(':id', exp.id),
                                          extra: exp,
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 6),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // 5. Primary Add Expense Action
      floatingActionButton: BouncingButton(
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
    );
  }
}

// =============================================================================
// ANIMATED FILTER CHIP
// =============================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? CoSpendColors.jadeGreen : CoSpendColors.prussianBlue;
    final inactiveBg = isDark ? CoSpendColors.darkCard : CoSpendColors.white;
    final activeText = Colors.white;
    final inactiveText = isDark ? Colors.white.withValues(alpha: 0.8) : CoSpendColors.textPrimary;

    return Semantics(
      label: '$label filter',
      selected: isSelected,
      button: true,
      child: BouncingButton(
        scale: 0.95,
        onTap: onTap,
        child: AnimatedContainer(
          duration: CoSpendAnimations.fast,
          curve: CoSpendAnimations.curveDefault,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: CoSpendRadii.pillRadius,
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight),
              width: 1,
            ),
            boxShadow: (!isDark && !isSelected) ? CoSpendShadows.cardSubtle : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? activeText : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeText : inactiveText,
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
// TIMELINE EXPENSE TILE
// =============================================================================

class _TimelineExpenseTile extends StatefulWidget {
  const _TimelineExpenseTile({
    super.key,
    required this.expense,
    required this.payerName,
    required this.household,
    required this.isDark,
    required this.shouldAnimate,
    required this.onAnimated,
    required this.onTap,
  });

  final Expense expense;
  final String payerName;
  final dynamic household;
  final bool isDark;
  final bool shouldAnimate;
  final VoidCallback onAnimated;
  final VoidCallback onTap;

  @override
  State<_TimelineExpenseTile> createState() => _TimelineExpenseTileState();
}

class _TimelineExpenseTileState extends State<_TimelineExpenseTile> {
  @override
  void initState() {
    super.initState();
    if (widget.shouldAnimate) {
      widget.onAnimated();
    }
  }

  String _formatSpentTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.expense;
    final isDark = widget.isDark;

    final custom = exp.customCategoryId != null
        ? widget.household?.customCategories
            ?.where((c) => c.id == exp.customCategoryId)
            ?.firstOrNull
        : null;
    final catIcon = custom?.icon ?? exp.category.icon;
    final catColor = custom?.color ?? exp.category.color;
    final hasSubcat = exp.subcategory != null && exp.subcategory!.trim().isNotEmpty;

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BouncingButton(
        scale: 0.98,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
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

              // Description + Payer + Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Paid by ${widget.payerName} · ${_formatSpentTime(exp.spentAt)}',
                            style: TextStyle(
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasSubcat) ...[
                          Text(
                            ' · ${exp.subcategory}',
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
                Money.format(exp.amountPaisa),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? CoSpendColors.darkBorder : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );

    // Only animate entrance for newly inserted items or initial render;
    // do not restart when Firestore emits a normal update!
    if (widget.shouldAnimate) {
      return TweenAnimationBuilder<double>(
        duration: CoSpendAnimations.medium,
        curve: CoSpendAnimations.curveEntrance,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1.0 - value) * 12),
              child: child,
            ),
          );
        },
        child: tile,
      );
    }

    return tile;
  }
}

// =============================================================================
// LOADING SKELETON
// =============================================================================

class _ExpensesSkeleton extends StatelessWidget {
  const _ExpensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        // Title Skeleton
        SkeletonBox(height: 24, width: 120, radius: 6),
        SizedBox(height: 16),

        // Search Bar Skeleton
        SkeletonBox(height: 46, radius: 12),
        SizedBox(height: 14),

        // Chips Skeleton
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              SkeletonBox(height: 34, width: 50, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(height: 34, width: 70, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(height: 34, width: 85, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(height: 34, width: 70, radius: 17),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Section 1 Skeleton
        SkeletonBox(height: 14, width: 80, radius: 4),
        SizedBox(height: 10),
        SkeletonBox(height: 64, radius: 14),
        SizedBox(height: 8),
        SkeletonBox(height: 64, radius: 14),
        SizedBox(height: 18),

        // Section 2 Skeleton
        SkeletonBox(height: 14, width: 80, radius: 4),
        SizedBox(height: 10),
        SkeletonBox(height: 64, radius: 14),
      ],
    );
  }
}