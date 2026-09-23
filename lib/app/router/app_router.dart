import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_system.dart';
import '../../features/auth/domain/session_state.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/dashboard/presentation/screens/category_budget_screen.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_details_screen.dart';
import '../../features/household/presentation/screens/create_flat_screen.dart';
import '../../features/household/presentation/screens/household_settings_screen.dart';
import '../../features/household/presentation/screens/household_setup_screen.dart';
import '../../features/household/presentation/screens/join_flat_screen.dart';
import '../../features/shell/presentation/screens/app_shell_screen.dart';
import '../../features/shell/presentation/screens/expenses_screen.dart';
import '../../features/shell/presentation/screens/home_screen.dart';
import '../../features/shell/presentation/screens/more_screen.dart';
import '../../features/shell/presentation/screens/settle_up_screen.dart';
import 'not_found_screen.dart';
import 'routes.dart';

/// Routes reachable while signed out. Everything else requires a session.
const Set<String> _authPaths = {
  Routes.onboarding,
  Routes.welcome,
  Routes.login,
  Routes.signup,
  Routes.forgotPassword,
};

/// Routes reachable right after sign-up, before a household exists.
const Set<String> _householdSetupPaths = {
  Routes.householdSetup,
  Routes.createFlat,
  Routes.joinFlat,
};

/// App-wide router, rebuilt whenever the session changes so every redirect
/// runs against the latest auth/household state.
final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(sessionProvider);

  final router = GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Routes.splash),
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.signup,
        name: 'signup',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: Routes.householdSetup,
        name: 'household-setup',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const HouseholdSetupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.createFlat,
        name: 'create-flat',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const CreateFlatScreen(),
        ),
      ),
      GoRoute(
        path: Routes.joinFlat,
        name: 'join-flat',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const JoinFlatScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.householdSettings,
        name: 'household-settings',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const HouseholdSettingsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.settle,
        redirect: (context, state) => Routes.categoryBudgets,
      ),
      GoRoute(
        path: Routes.settlementHistory,
        name: 'settlements',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const SettleUpScreen(),
        ),
      ),
      GoRoute(
        path: Routes.addExpense,
        name: 'add-expense',
        pageBuilder: (context, state) => coSpendPageTransition(
          context: context,
          state: state,
          child: const AddExpenseScreen(),
        ),
      ),
      GoRoute(
        path: Routes.expenseDetails,
        name: 'expense-details',
        pageBuilder: (context, state) {
          final expense = state.extra;
          Widget child;
          if (expense is Expense) {
            child = ExpenseDetailsScreen(expense: expense);
          } else {
            final id = state.pathParameters['id'] ?? '';
            child = Scaffold(
              appBar: AppBar(title: const Text('Expense Details')),
              body: Center(child: Text('Expense #$id')),
            );
          }
          return coSpendPageTransition(
            context: context,
            state: state,
            child: child,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.expenses,
                name: 'expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.categoryBudgets,
                name: 'category-budgets',
                builder: (context, state) => const CategoryBudgetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                name: 'more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) =>
        _redirect(state, ref.read(sessionProvider).value),
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(GoRouterState state, SessionState? session) {
  final path = state.uri.path;

  switch (session) {
    // Session still resolving: only the splash screen is allowed.
    case null || SessionInitializing():
      return path == Routes.splash ? null : Routes.splash;

    // Signed out: auth screens only.
    case SessionSignedOut():
      if (path == Routes.splash) return Routes.onboarding;
      if (_authPaths.contains(path)) return null;
      return Routes.onboarding;

    // Signed in but no household yet: household setup only.
    case SessionNeedsHousehold():
      if (_householdSetupPaths.contains(path)) return null;
      return Routes.householdSetup;

    // Full access; keep out of the auth/household-setup flows.
    case SessionReady():
      if (_authPaths.contains(path) ||
          _householdSetupPaths.contains(path) ||
          path == Routes.splash) {
        return Routes.home;
      }
      return null;
  }
}
