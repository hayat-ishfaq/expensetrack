/// Central route paths — the navigation contract for the whole app.
///
/// Keep in sync with the GoRouter table in `app_router.dart`. Phases 3+ add
/// the corresponding screens; paths are declared up front so features can
/// navigate without hardcoding string literals.
abstract final class Routes {
  // Auth
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Household
  static const String householdSetup = '/household/setup';
  static const String createFlat = '/household/create';
  static const String joinFlat = '/household/join';
  static const String householdSettings = '/household/settings';
  static const String categoryBudgets = '/household/budgets';

  // Bottom navigation shell
  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String settle = '/settle';
  static const String more = '/more';

  // Details / sub-screens
  static const String addExpense = '/expenses/new';
  static const String expenseDetails = '/expenses/:id';
  static const String editExpense = '/expenses/:id/edit';
  static const String monthlySummary = '/summary';
  static const String settlementHistory = '/settlements';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
}
