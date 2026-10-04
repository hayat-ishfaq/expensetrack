import 'package:expensetrack/features/auth/domain/session_state.dart';
import 'package:expensetrack/features/auth/presentation/providers/session_provider.dart';
import 'package:expensetrack/features/household/domain/household_notification.dart';
import 'package:expensetrack/features/household/presentation/providers/notification_providers.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unreadNotificationCountProvider calculates unread count accurately', () async {
    final user = AppUser(
      id: 'user-1',
      name: 'Alice',
      email: 'alice@example.com',
      householdId: 'hh-1',
      createdAt: DateTime(2026, 1, 1),
    );

    final notifs = [
      HouseholdNotification(
        id: 'notif-1',
        householdId: 'hh-1',
        title: 'New Expense',
        body: 'Bob added Grocery',
        amountPaisa: 5000,
        category: 'Food',
        payerName: 'Bob',
        payerId: 'user-2',
        createdAt: DateTime(2026, 10, 1),
        readByUserIds: const [], // unread by Alice
      ),
      HouseholdNotification(
        id: 'notif-2',
        householdId: 'hh-1',
        title: 'Settlement',
        body: 'Charlie settled up',
        amountPaisa: 2000,
        category: 'Settlement',
        payerName: 'Charlie',
        payerId: 'user-3',
        createdAt: DateTime(2026, 10, 2),
        readByUserIds: const ['user-1'], // already read by Alice
      ),
      HouseholdNotification(
        id: 'notif-3',
        householdId: 'hh-1',
        title: 'Roommate Joined',
        body: 'Dave joined',
        amountPaisa: 0,
        category: 'Household',
        payerName: 'Dave',
        payerId: 'user-4',
        createdAt: DateTime(2026, 10, 3),
        readByUserIds: const [], // unread by Alice
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _FakeSessionController(SessionReady(user: user)),
        ),
        householdNotificationsProvider.overrideWithValue(
          AsyncData(notifs),
        ),
      ],
    );

    await container.read(sessionProvider.future);

    // Initial check: 2 unread (notif-1 and notif-3)
    expect(container.read(unreadNotificationCountProvider), equals(2));

    // When notif-1 is seen locally, badge count immediately decrements to 1
    container
        .read(locallyReadNotificationIdsProvider.notifier)
        .markOne('notif-1');
    expect(container.read(unreadNotificationCountProvider), equals(1));

    // When all are seen locally, badge count immediately becomes 0
    container
        .read(locallyReadNotificationIdsProvider.notifier)
        .markIds(['notif-1', 'notif-3']);
    expect(container.read(unreadNotificationCountProvider), equals(0));
  });
}

class _FakeSessionController extends AsyncNotifier<SessionState>
    implements SessionController {
  _FakeSessionController(this._state);
  final SessionState _state;

  @override
  Future<SessionState> build() async => _state;
}
