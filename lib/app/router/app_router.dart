import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/session_state.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/dashboard/presentation/screens/category_budget_screen.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_details_screen.dart';
import '../../features/household/presentation/screens/create_flat_screen.dart';
import '../../features/household/presentation/screens/household_settings_screen.dart';
import '../../features/household/presentation/screens/household_setup_screen.dart';
import '../../features/household/presentation/screens/join_flat_screen.dart';
import '../../features/settlement/presentation/screens/settle_up_screen.dart';
import '../../features/shell/presentation/screens/app_shell_screen.dart';
import '../../features/shell/presentation/screens/contact_support_screen.dart';
import '../../features/shell/presentation/screens/expenses_screen.dart';
import '../../features/shell/presentation/screens/help_faq_screen.dart';
import '../../features/shell/presentation/screens/home_screen.dart';
import '../../features/shell/presentation/screens/more_screen.dart';
import '../../splash_screen.dart';
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

/// Listenable adapter notifying GoRouter when the session state transitions or
/// when the initial splash presentation window has completed.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<AsyncValue<SessionState>>(sessionProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<bool>(splashAnimationCompletedProvider, (_, _) {
      notifyListeners();
    });
  }
}

/// App-wide router, stable across session changes while reacting to auth redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionListenable = _SessionListenable(ref);
  ref.onDispose(sessionListenable.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: sessionListenable,
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
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.householdSetup,
        name: 'household-setup',
        builder: (context, state) => const HouseholdSetupScreen(),
      ),
      GoRoute(
        path: Routes.createFlat,
        name: 'create-flat',
        builder: (context, state) => const CreateFlatScreen(),
      ),
      GoRoute(
        path: Routes.joinFlat,
        name: 'join-flat',
        builder: (context, state) => const JoinFlatScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.helpFaq,
        name: 'help-faq',
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: Routes.contactSupport,
        name: 'contact-support',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      GoRoute(
        path: Routes.settle,
        name: 'settle',
        builder: (context, state) => const SettleUpScreen(),
      ),
      GoRoute(
        path: Routes.householdSettings,
        name: 'household-settings',
        builder: (context, state) => const HouseholdSettingsScreen(),
      ),
      GoRoute(
        path: Routes.addExpense,
        name: 'add-expense',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: Routes.expenseDetails,
        name: 'expense-details',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Expense) {
            return ExpenseDetailsScreen(expense: extra);
          }
          return ExpenseDetailsScreen(
            expenseId: state.pathParameters['id'],
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
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      final isSplashAnimationComplete =
          ref.read(splashAnimationCompletedProvider);
      return _redirect(state, session, isSplashAnimationComplete);
    },
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(
  GoRouterState state,
  SessionState? session,
  bool isSplashAnimationComplete,
) {
  final path = state.uri.path;

  // On cold start / initial app launch, remain on splash until the Lottie
  // animation completes.
  if (!isSplashAnimationComplete && (path == Routes.splash || path == '/')) {
    return null;
  }

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
      if (_authPaths.contains(path) || path == Routes.splash) {
        return Routes.home;
      }
      if (path == Routes.householdSetup || path == Routes.createFlat) {
        return Routes.home;
      }
      return null;
  }
}
