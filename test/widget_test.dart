import 'package:expensetrack/app/app.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('signed-out user lands on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fakeAuth = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
        child: const FlatSplitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared expenses,\nsimplified.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}