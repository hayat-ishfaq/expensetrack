import 'package:expensetrack/core/constants/app_constants.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets('SplashScreen displays brand name and mounts properly',
      (tester) async {
    final fakeAuth = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify brand assets are rendered on screen
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);

    // Advance past the fallback timer window
    await tester.pump(const Duration(seconds: 3));

    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
