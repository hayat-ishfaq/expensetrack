import 'package:expensetrack/core/theme/design_system.dart';
import 'package:expensetrack/features/auth/presentation/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility & Reduced Motion Tests', () {
    testWidgets('isReducedMotionEnabled detects disableAnimations', (tester) async {
      bool? reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = isReducedMotionEnabled(context);
              return const Placeholder();
            },
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    testWidgets('isReducedMotionEnabled detects accessibleNavigation', (tester) async {
      bool? reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Builder(
            builder: (context) {
              reduced = isReducedMotionEnabled(context);
              return const Placeholder();
            },
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    testWidgets('isReducedMotionEnabled returns false when standard animations allowed', (tester) async {
      bool? reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              reduced = isReducedMotionEnabled(context);
              return const Placeholder();
            },
          ),
        ),
      );
      expect(reduced, isFalse);
    });

    testWidgets('CoSpendFadeSlide renders direct child when reduced motion enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: CoSpendFadeSlide(
                child: Text('Reduced Motion Active'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Reduced Motion Active'), findsOneWidget);
    });
  });

  group('Semantic Hierarchy & Roles Tests', () {
    testWidgets('CoSpendButton has button semantic role and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoSpendButton(
              label: 'Save Changes',
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CoSpendButton));
      final data = semantics.getSemanticsData();
      expect(data.label, contains('Save Changes'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('CoSpendIconButton has min 48x48 hit area and semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CoSpendIconButton(
                icon: Icons.edit,
                semanticLabel: 'Edit Expense',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconButtonFinder = find.byType(CoSpendIconButton);
      final size = tester.getSize(iconButtonFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      final semantics = tester.getSemantics(iconButtonFinder);
      final data = semantics.getSemanticsData();
      expect(data.label, contains('Edit Expense'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('CoSpendChip has button role, selected status, and comfortable hit area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CoSpendChip(
                label: 'Groceries',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final chipFinder = find.byType(CoSpendChip);
      final size = tester.getSize(chipFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));

      final semantics = tester.getSemantics(chipFinder);
      final data = semantics.getSemanticsData();
      expect(data.label, contains('Groceries filter'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('CoSpendProgressBar announces progress percentage and status label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoSpendProgressBar(
              percentUsed: 75.0,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CoSpendProgressBar));
      final data = semantics.getSemanticsData();
      expect(data.label, contains('Budget progress'));
      expect(data.value, contains('75% used'));
      expect(data.value, contains('On track'));
    });

    testWidgets('PasswordField provides show/hide semantic action and 48x48 toggle button', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordField(controller: controller),
          ),
        ),
      );

      // Verify toggle button semantics
      final toggleFinder = find.byType(IconButton);
      expect(toggleFinder, findsOneWidget);

      final size = tester.getSize(toggleFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      final data = tester.getSemantics(toggleFinder).getSemanticsData();
      final hasShowLabel = data.label == 'Show password' || data.tooltip == 'Show password';
      expect(hasShowLabel, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      // Tap toggle and verify semantics update
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      final updatedData = tester.getSemantics(toggleFinder).getSemanticsData();
      final hasHideLabel = updatedData.label == 'Hide password' || updatedData.tooltip == 'Hide password';
      expect(hasHideLabel, isTrue);
    });
  });

  group('Text Scaling Resilience Tests', () {
    testWidgets('HeroBudgetCard renders without overflow at 1.5x font scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.5),
            ),
            child: const Scaffold(
              body: HeroBudgetCard(
                title: 'SEPTEMBER 2026',
                subtitle: '7 days remaining',
                amountText: 'Rs. 15,000 left',
                percentUsed: 70.0,
                progressText: '70% spent of Rs. 50,000',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    });

    testWidgets('HeroBudgetCard renders without overflow at 2.0x font scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: const Scaffold(
              body: HeroBudgetCard(
                title: 'SEPTEMBER 2026',
                subtitle: 'Exceeded by Rs. 5,000',
                amountText: 'Rs. 0 left',
                percentUsed: 110.0,
                progressText: '110% spent of Rs. 50,000',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    });

    testWidgets('CoSpendAmountField renders comfortably at 1.5x font scale', (tester) async {
      final controller = TextEditingController(text: '12,500');
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: CoSpendAmountField(
                controller: controller,
                currencyPrefix: 'Rs.',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('12,500'), findsOneWidget);
    });
  });
}
