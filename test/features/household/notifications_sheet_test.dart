import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/household/domain/household_notification.dart';
import 'package:expensetrack/features/household/presentation/providers/notification_providers.dart';
import 'package:expensetrack/features/household/presentation/widgets/notifications_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  final testNotifications = [
    // Today: Expense notification (Unread)
    HouseholdNotification(
      id: 'n1',
      householdId: 'hh-1',
      title: 'Ali spent Rs. 1,200',
      body: 'Rs. 1,200 on Groceries (Milk & Eggs)',
      amountPaisa: 120000,
      category: 'Groceries',
      subcategory: 'Milk & Eggs',
      payerName: 'Ali',
      payerId: 'u-ali',
      createdAt: now.subtract(const Duration(minutes: 15)),
    ),
    // Today: Budget Exceeded notification (Unread)
    HouseholdNotification(
      id: 'n2',
      householdId: 'hh-1',
      title: 'Budget Exceeded!',
      body: 'Electricity budget has exceeded by Rs. 500',
      amountPaisa: 0,
      category: 'Budget',
      payerName: 'System',
      payerId: '',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    // Yesterday: Settlement notification
    HouseholdNotification(
      id: 'n3',
      householdId: 'hh-1',
      title: 'Settlement Completed',
      body: 'Sara settled Rs. 2,500 with Ali',
      amountPaisa: 250000,
      category: 'Settlement',
      payerName: 'Sara',
      payerId: 'u-sara',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    ),
    // Earlier: Household invite / member join
    HouseholdNotification(
      id: 'n4',
      householdId: 'hh-1',
      title: 'New Member Joined',
      body: 'Ahmed joined your household',
      amountPaisa: 0,
      category: 'Household',
      payerName: 'Ahmed',
      payerId: 'u-ahmed',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    // Earlier: Budget Approaching limit
    HouseholdNotification(
      id: 'n5',
      householdId: 'hh-1',
      title: 'Budget Approaching Limit',
      body: 'Food budget is at 85% of monthly cap',
      amountPaisa: 0,
      category: 'Budget',
      payerName: 'System',
      payerId: '',
      createdAt: now.subtract(const Duration(days: 6)),
    ),
    // Earlier: System notification
    HouseholdNotification(
      id: 'n6',
      householdId: 'hh-1',
      title: 'System Update',
      body: 'CoSpend updated with new reconciliation engine',
      amountPaisa: 0,
      category: 'System',
      payerName: 'CoSpend',
      payerId: '',
      createdAt: now.subtract(const Duration(days: 10)),
    ),
  ];

  Widget buildSheet({
    List<HouseholdNotification>? notifications,
    DateTime? lastViewedTime,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    // Default lastViewed is 3 hours ago so n1 and n2 are unread
    final initialLastViewed =
        lastViewedTime ?? now.subtract(const Duration(hours: 3));

    return ProviderScope(
      overrides: [
        householdNotificationsProvider
            .overrideWith((ref) => Stream.value(notifications ?? testNotifications)),
        lastViewedNotificationProvider
            .overrideWith(() => _TestLastViewedNotifier(initialLastViewed)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const Scaffold(
          body: NotificationsSheet(),
        ),
      ),
    );
  }

  group('NotificationsSheet Redesign Tests', () {
    testWidgets('renders header with unread count and mark all as read button',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2 new'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('groups notifications by Today, Yesterday, and Earlier',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);
    });

    testWidgets('distinguishes notification types with proper badges',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Check Budget Exceeded badge
      expect(find.text('BUDGET EXCEEDED'), findsOneWidget);

      // Check Settlement badge
      expect(find.text('SETTLEMENT'), findsOneWidget);

      // Check Household badge
      expect(find.text('HOUSEHOLD'), findsOneWidget);

      // Check Budget Limit badge
      expect(find.text('BUDGET LIMIT'), findsOneWidget);

      // Check System badge
      expect(find.text('SYSTEM'), findsOneWidget);

      // Check formatted amount
      expect(find.text('Rs. 1,200'), findsOneWidget);
      expect(find.text('Rs. 2,500'), findsOneWidget);
    });

    testWidgets('tapping Mark all read marks all as read and updates count',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('2 new'), findsOneWidget);

      // Tap Mark all read
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // Unread count chip should disappear
      expect(find.text('2 new'), findsNothing);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('tapping an individual notification marks it as read',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('2 new'), findsOneWidget);

      // Tap the first notification card
      await tester.tap(find.byKey(const ValueKey('notification_n1')));
      await tester.pumpAndSettle();

      // Now only 1 should be unread
      expect(find.text('1 new'), findsOneWidget);
    });

    testWidgets('renders intentional empty state when no notifications exist',
        (tester) async {
      await tester.pumpWidget(buildSheet(notifications: []));
      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('Inbox zero'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSheet(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on compact screen (320x480) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestLastViewedNotifier extends LastViewedNotificationNotifier {
  _TestLastViewedNotifier(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;

  @override
  void markAllAsRead() {
    state = DateTime.now();
  }
}
