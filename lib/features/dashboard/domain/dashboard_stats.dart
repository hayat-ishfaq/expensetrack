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
    this.userCategorySpending = const {},
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

  /// Category spending for the current user (amount paid by this user): Category -> amount in paisa.
  final Map<ExpenseCategory, int> userCategorySpending;

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
    final dayMap = <int, int>{};

    for (final exp in monthExpenses) {
      totalPaisa += exp.amountPaisa;

      // Track how much user paid
      if (exp.paidById == userId) {
        userPaid += exp.amountPaisa;
        userCatMap[exp.category] =
            (userCatMap[exp.category] ?? 0) + exp.amountPaisa;
      }

      // Track user share from splits
      final userIndex = exp.splitAmongIds.indexOf(userId);
      if (userIndex != -1 && userIndex < exp.splitAmountsPaisa.length) {
        userShare += exp.splitAmountsPaisa[userIndex];
      }

      // Category breakdown for household
      categoryMap[exp.category] =
          (categoryMap[exp.category] ?? 0) + exp.amountPaisa;

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
      userCategorySpending: userCatMap,
      dailySpending: dayMap,
      expenseCount: monthExpenses.length,
      highestCategory: highestCat,
      highestSpendingDay: highestDay,
    );
  }
}
