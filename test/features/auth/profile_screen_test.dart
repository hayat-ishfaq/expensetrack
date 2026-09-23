import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/screens/profile_screen.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
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
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Redesign Tests', () {
    testWidgets('renders profile header with name, email, avatar, and role',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Ali Khan'), findsWidgets);
      expect(find.text('ali@example.com'), findsWidgets);
      expect(find.text('Flat Owner'), findsOneWidget);
      expect(find.text('Sunset Flats'), findsWidgets);
      expect(find.text('Edit Profile & Room Details'), findsOneWidget);
    });

    testWidgets('displays account information with contact and resident details',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT INFORMATION'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
      expect(find.text('ali@okhdfcbank'), findsOneWidget);
      expect(find.text('Room 204 • Early riser'), findsOneWidget);
    });

    testWidgets('renders household summary card with invite code and member count',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('HOUSEHOLD & FLAT'), findsOneWidget);
      expect(find.text('FLAT-7K29'), findsOneWidget);
      expect(find.text('3 members · You are Owner'), findsOneWidget);
      expect(find.text('Manage Flat & Member Roster'), findsOneWidget);
    });

    testWidgets('distinguishes member role and displays Leave Flat option for non-owner',
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
      // Owner is Ali (u-ali), so Sara (u-sara) is a Member
      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.text('Flatmate'), findsOneWidget);
      expect(find.text('3 members · Member'), findsOneWidget);
      expect(find.text('Leave Flat'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Ali Khan'), findsWidgets);
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

      expect(find.text('My Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
