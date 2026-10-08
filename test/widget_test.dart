import 'package:expensetrack/app/app.dart';
import 'package:expensetrack/features/auth/domain/session_state.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/providers/session_provider.dart';
import 'package:expensetrack/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._state);
  final SessionState _state;
  @override
  Future<SessionState> build() async => _state;
}

void main() {
  testWidgets('signed-out user lands on the onboarding screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fakeAuth = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          sessionProvider.overrideWith(
            () => _FakeSessionController(const SessionSignedOut()),
          ),
        ],
        child: const CoSpendApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Track Together'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}