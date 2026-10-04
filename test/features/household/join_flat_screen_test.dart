import 'package:expensetrack/app/router/routes.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/providers/session_provider.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/household/presentation/screens/join_flat_screen.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_household_repository.dart';

void main() {
  late FakeHouseholdRepository fakeHousehold;
  late FakeAuthRepository fakeAuth;

  setUp(() {
    fakeHousehold = FakeHouseholdRepository();
    fakeAuth = FakeAuthRepository(
      currentUser: const AuthUser(uid: 'u-1', email: 'test@example.com'),
      appUser: AppUser(
        id: 'u-1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime(2026, 9, 1),
      ),
    );
  });

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: Routes.joinFlat,
      routes: [
        GoRoute(
          path: Routes.joinFlat,
          builder: (context, state) => const JoinFlatScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Destination')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        firebaseInitProvider.overrideWith((ref) async {}),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        householdRepositoryProvider.overrideWithValue(fakeHousehold),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders input fields, instructions, and Join button',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Join a flat'), findsOneWidget);
    expect(
      find.text(
        'Enter the invite code your roommate shared. It looks like FLAT-7K29.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Join flat'), findsOneWidget);
    expect(
      find.text(
        'The code is case-insensitive — "flat-7k29" works the same as FLAT-7K29.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('validates empty invite code', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join flat'));
    await tester.pumpAndSettle();

    expect(find.text('Invite code is required.'), findsOneWidget);
    expect(fakeHousehold.lastJoinedInviteCode, isNull);
  });

  testWidgets('validates invalid format invite code', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'INVALID-CODE');
    await tester.tap(find.text('Join flat'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid invite code (e.g. FLAT-7K29).'),
      findsOneWidget,
    );
    expect(fakeHousehold.lastJoinedInviteCode, isNull);
  });

  testWidgets('normalizes lowercase code and short code on submission',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Suffix only in lowercase
    await tester.enterText(find.byType(TextField), '7k29');
    await tester.tap(find.text('Join flat'));
    await tester.pumpAndSettle();

    expect(fakeHousehold.lastJoinedInviteCode, equals('FLAT-7K29'));
    expect(find.text('Home Destination'), findsOneWidget);
  });

  testWidgets('submits standard code, joins flat, and navigates home',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'FLAT-8M3X');
    await tester.tap(find.text('Join flat'));
    await tester.pumpAndSettle();

    expect(fakeHousehold.lastJoinedInviteCode, equals('FLAT-8M3X'));
    expect(find.text('Successfully joined flat!'), findsOneWidget);
    expect(find.text('Home Destination'), findsOneWidget);
  });

  testWidgets('displays error snackbar when join fails', (tester) async {
    fakeHousehold.shouldThrowOnJoin = true;
    fakeHousehold.joinThrowMessage =
        "That invite code doesn't match any flat.";

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'FLAT-9999');
    await tester.tap(find.text('Join flat'));
    await tester.pumpAndSettle();

    expect(
      find.text("That invite code doesn't match any flat."),
      findsOneWidget,
    );
    expect(find.text('Home Destination'), findsNothing);
  });
}
