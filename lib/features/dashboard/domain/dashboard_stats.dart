import '../../expenses/domain/expense.dart';
import '../../expenses/domain/expense_category.dart';

/// Aggregated monthly financial statistics for the dashboard.
class DashboardStats {
  const DashboardStats({
    required this.totalSpendingPaisa,
    required this.userSharePaisa,
    required this.userPaidPaisa,
    required this.userBalancePaisa,
    required this.categoryBreakdown,
    this.categoryIdBreakdown = const {},
    this.userCategorySpending = const {},
    this.userCategoryIdBreakdown = const {},
    this.userPaidCategorySpending = const {},
    this.userPaidCategoryIdBreakdown = const {},
    required this.dailySpending,
    required this.expenseCount,
    this.highestCategory,
    this.highestSpendingDay,
  });

  /// Total household expenditure in the month.
  final int totalSpendingPaisa;

  /// Amount the current user is responsible for.
  final int userSharePaisa;

  /// Amount the current user fronted.
  final int userPaidPaisa;

  /// Net balance: `userPaidPaisa - userSharePaisa`.
  /// Positive: should receive money (+Rs. X)
  /// Negative: owes money (-Rs. Y)
  /// Zero: settled
  final int userBalancePaisa;

  /// Category breakdown for the entire household: Category -> amount in paisa.
  final Map<ExpenseCategory, int> categoryBreakdown;

  /// Map of category ID (standard or custom) -> amount in paisa for the household.
  final Map<String, int> categoryIdBreakdown;

  /// Category spending for the current user (their allocated share): Category -> amount in paisa.
  final Map<ExpenseCategory, int> userCategorySpending;

  /// Map of category ID -> user's allocated share in paisa.
  final Map<String, int> userCategoryIdBreakdown;

  /// Category spending fronted/paid out-of-pocket by the current user.
  final Map<ExpenseCategory, int> userPaidCategorySpending;

  /// Map of category ID -> amount fronted by this user in paisa.
  final Map<String, int> userPaidCategoryIdBreakdown;

  /// Daily spending map: Day of month (1..31) -> amount in paisa.
  final Map<int, int> dailySpending;

  /// Total number of expenses recorded in the month.
  final int expenseCount;

  /// Category with the highest spending in this month.
  final ExpenseCategory? highestCategory;

  /// Day of the month with the highest spending.
  final int? highestSpendingDay;

  /// Factory computing stats from a list of expenses for [userId] in [targetMonth].
  factory DashboardStats.fromExpenses({
    required List<Expense> allExpenses,
    required String userId,
    required DateTime targetMonth,
  }) {
    // Filter expenses to the target month & year
    final monthExpenses = allExpenses.where((e) {
      return e.spentAt.year == targetMonth.year &&
          e.spentAt.month == targetMonth.month;
    }).toList();

    var totalPaisa = 0;
    var userShare = 0;
    var userPaid = 0;
    final categoryMap = <ExpenseCategory, int>{};
    final userCatMap = <ExpenseCategory, int>{};
    final categoryIdMap = <String, int>{};
    final userCategoryIdMap = <String, int>{};
    final userPaidCatMap = <ExpenseCategory, int>{};
    final userPaidCategoryIdMap = <String, int>{};
    final dayMap = <int, int>{};

    for (final exp in monthExpenses) {
      totalPaisa += exp.amountPaisa;
      final catKey = exp.customCategoryId ?? exp.category.id;

      // Track how much user paid out of pocket
      if (exp.paidById == userId) {
        userPaid += exp.amountPaisa;
        userPaidCatMap[exp.category] =
            (userPaidCatMap[exp.category] ?? 0) + exp.amountPaisa;
        userPaidCategoryIdMap[catKey] =
            (userPaidCategoryIdMap[catKey] ?? 0) + exp.amountPaisa;
      }

      // Track user share from splits (true personal consumption)
      final userIndex = exp.splitAmongIds.indexOf(userId);
      if (userIndex != -1 && userIndex < exp.splitAmountsPaisa.length) {
        final share = exp.splitAmountsPaisa[userIndex];
        userShare += share;
        userCatMap[exp.category] =
            (userCatMap[exp.category] ?? 0) + share;
        userCategoryIdMap[catKey] =
            (userCategoryIdMap[catKey] ?? 0) + share;
      }

      // Category breakdown for household
      categoryMap[exp.category] =
          (categoryMap[exp.category] ?? 0) + exp.amountPaisa;
      categoryIdMap[catKey] =
          (categoryIdMap[catKey] ?? 0) + exp.amountPaisa;

      // Daily spending
      final day = exp.spentAt.day;
      dayMap[day] = (dayMap[day] ?? 0) + exp.amountPaisa;
    }

    // Find highest category
    ExpenseCategory? highestCat;
    var highestCatAmt = -1;
    categoryMap.forEach((cat, amt) {
      if (amt > highestCatAmt) {
        highestCatAmt = amt;
        highestCat = cat;
      }
    });

    // Find highest day
    int? highestDay;
    var highestDayAmt = -1;
    dayMap.forEach((day, amt) {
      if (amt > highestDayAmt) {
        highestDayAmt = amt;
        highestDay = day;
      }
    });

    return DashboardStats(
      totalSpendingPaisa: totalPaisa,
      userSharePaisa: userShare,
      userPaidPaisa: userPaid,
      userBalancePaisa: userPaid - userShare,
      categoryBreakdown: categoryMap,
      categoryIdBreakdown: categoryIdMap,
      userCategorySpending: userCatMap,
      userCategoryIdBreakdown: userCategoryIdMap,
      userPaidCategorySpending: userPaidCatMap,
      userPaidCategoryIdBreakdown: userPaidCategoryIdMap,
      dailySpending: dayMap,
      expenseCount: monthExpenses.length,
      highestCategory: highestCat,
      highestSpendingDay: highestDay,
    );
  }
}
