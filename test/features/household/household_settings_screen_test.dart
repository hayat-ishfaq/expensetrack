import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/household/presentation/screens/household_settings_screen.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_household_repository.dart';

void main() {
  final testAppUser = AppUser(
    id: 'u-ali',
    name: 'Ali Khan',
    email: 'ali@example.com',
    photoUrl: null,
    phone: '+92 300 1234567',
    upiId: 'ali@okhdfcbank',
    bio: 'Room 204 • Early riser',
    householdId: 'hh-1',
    createdAt: DateTime(2026, 9, 1),
  );

  final testHousehold = Household(
    id: 'hh-1',
    name: 'Sunset Flats',
    ownerId: 'u-ali',
    inviteCode: 'FLAT-7K29',
    memberCount: 3,
    monthlyBudgetPaisa: 5000000,
    categoryBudgetsPaisa: {'food': 2500000, 'electricity': 1500000},
    currency: 'PKR',
    createdAt: DateTime(2026, 9, 1),
  );

  final testMembers = [
    HouseholdMember(
      id: 'u-ali',
      name: 'Ali Khan',
      email: 'ali@example.com',
      role: MemberRole.owner,
      joinedAt: DateTime(2026, 9, 1),
    ),
    HouseholdMember(
      id: 'u-sara',
      name: 'Sara Ahmed',
      email: 'sara@example.com',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 9, 2),
    ),
    HouseholdMember(
      id: 'u-bilal',
      name: 'Bilal Tariq',
      email: 'bilal@example.com',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 9, 3),
    ),
  ];

  Widget buildScreen({
    AppUser? user,
    Household? household,
    List<HouseholdMember>? members,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final effectiveUser = user ?? testAppUser;
    final effectiveHousehold = household ?? testHousehold;
    final effectiveMembers = members ?? testMembers;

    final fakeAuth = FakeAuthRepository(
      currentUser: AuthUser(uid: effectiveUser.id, email: effectiveUser.email),
      appUser: effectiveUser,
    );

    final fakeHousehold = FakeHouseholdRepository(
      household: effectiveHousehold,
      members: effectiveMembers,
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        householdRepositoryProvider.overrideWithValue(fakeHousehold),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const HouseholdSettingsScreen(),
      ),
    );
  }

  group('HouseholdSettingsScreen Redesign Tests', () {
    testWidgets('renders household hero card with name, status, and role badge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Household Management'), findsOneWidget);
      expect(find.text('Sunset Flats'), findsWidgets);
      expect(find.text('Active Flat'), findsOneWidget);
      expect(find.text('3 Flatmates'), findsOneWidget);
      expect(find.text('You are Owner'), findsOneWidget);
    });

    testWidgets('renders invite code card with copy and share buttons',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('ROOMMATE INVITE CODE'), findsOneWidget);
      expect(find.text('FLAT-7K29'), findsOneWidget);
      expect(find.text('Copy Code'), findsWidgets);
      expect(find.text('Share Invite'), findsWidgets);
    });

    testWidgets('renders full member roster with avatars and role badges',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('FLATMATES (3)'), findsOneWidget);
      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('Bilal Tariq'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('Owner'), findsWidgets);
      expect(find.text('Member'), findsWidgets);
    });

    testWidgets('owner sees owner management controls including rename flat',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('OWNER MANAGEMENT'), findsOneWidget);
      expect(find.text('Category Budgets & Limits'), findsOneWidget);
      expect(find.text('Rename Flat'), findsWidgets);
    });

    testWidgets('member sees view-only flat overview with permission explanation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final memberUser = AppUser(
        id: 'u-sara',
        name: 'Sara Ahmed',
        email: 'sara@example.com',
        householdId: 'hh-1',
        createdAt: DateTime(2026, 9, 2),
      );
      // u-sara is a member
      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.text('You are Member'), findsOneWidget);
      expect(find.text('FLAT OVERVIEW'), findsOneWidget);
      expect(find.text('Category Spending & Limits'), findsOneWidget);
      expect(find.textContaining('Managed by flat owner'), findsOneWidget);
      expect(find.text('Leave Flat'), findsOneWidget);
    });

    testWidgets('tapping Leave Flat opens confirmation dialog with consequence description',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final memberUser = AppUser(
        id: 'u-sara',
        name: 'Sara Ahmed',
        email: 'sara@example.com',
        householdId: 'hh-1',
        createdAt: DateTime(2026, 9, 2),
      );
      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      final leaveTile = find.widgetWithText(ListTile, 'Leave Flat');
      await tester.tap(leaveTile);
      await tester.pumpAndSettle();

      expect(find.text('Leave flat?'), findsOneWidget);
      expect(find.textContaining('You will be removed from "Sunset Flats"'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Leave Flat'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Sunset Flats'), findsWidgets);
      expect(find.text('FLAT-7K29'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on compact screen (320x480) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Household Management'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
