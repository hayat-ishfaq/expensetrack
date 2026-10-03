import 'package:expensetrack/app/router/routes.dart';
import 'package:expensetrack/core/errors/app_exception.dart';
import 'package:expensetrack/features/auth/domain/auth_repository.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_auth_repository.dart';

class TestAuthRepository extends FakeAuthRepository {
  String? lastResetEmail;
  bool shouldThrow = false;
  String throwMessage = 'No account found with this email address.';

  @override
  Future<void> sendPasswordReset({required String email}) async {
    lastResetEmail = email;
    if (shouldThrow) {
      throw AuthException(throwMessage);
    }
  }
}

void main() {
  late TestAuthRepository fakeAuth;

  setUp(() {
    fakeAuth = TestAuthRepository();
  });

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: Routes.forgotPassword,
      routes: [
        GoRoute(
          path: Routes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login Screen Destination')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders input fields, buttons, and links correctly', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('validates empty email input', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(fakeAuth.lastResetEmail, isNull);
  });

  testWidgets('validates invalid email format', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'invalid-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(fakeAuth.lastResetEmail, isNull);
  });

  testWidgets('submits valid email and transitions to success state', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'test@cospend.app');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(fakeAuth.lastResetEmail, equals('test@cospend.app'));

    // Check success state UI elements
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text('test@cospend.app'), findsOneWidget);
    expect(find.text('Open email app'), findsOneWidget);
    expect(find.text('Try a different email'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
    // Cooldown is active initially
    expect(find.textContaining('Resend link in'), findsOneWidget);
  });

  testWidgets('try different email returns to input form', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first@cospend.app');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox'), findsOneWidget);

    // Tap "Try a different email"
    await tester.tap(find.text('Try a different email'));
    await tester.pumpAndSettle();

    // Verify back on input form
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
  });

  testWidgets('handles error gracefully when repository fails', (tester) async {
    fakeAuth.shouldThrow = true;
    fakeAuth.throwMessage = 'No account found with this email address.';

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'missing@cospend.app');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    // Stays on input state with error displayed
    expect(find.text('Check your inbox'), findsNothing);
    expect(find.text('No account found with this email address.'), findsWidgets);
  });

  testWidgets('sign in link navigates to login', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen Destination'), findsOneWidget);
  });

  testWidgets('back to sign in from success state navigates to login', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'test@cospend.app');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Back to sign in'), findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen Destination'), findsOneWidget);
  });
}
