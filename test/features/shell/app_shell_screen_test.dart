import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/shell/presentation/screens/app_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildShellApp({
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
  }) {
    final router = customRouter ??
        GoRouter(
          initialLocation: '/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  AppShellScreen(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/home',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Home Screen Content')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/expenses',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Expenses Screen Content')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/budgets',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Budgets Screen Content')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/more',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('More Screen Content')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

    return MaterialApp.router(
      key: UniqueKey(),
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }

  group('AppShellScreen & Navigation Tests', () {
    testWidgets('renders all 4 tabs and starts on Home', (tester) async {
      await tester.pumpWidget(buildShellApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Home Screen Content'), findsOneWidget);
    });

    testWidgets('tapping tabs switches destinations seamlessly', (tester) async {
      await tester.pumpWidget(buildShellApp());
      await tester.pumpAndSettle();

      // Tap Expenses
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Expenses Screen Content'), findsOneWidget);

      // Tap Budgets
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();
      expect(find.text('Budgets Screen Content'), findsOneWidget);

      // Tap More
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('More Screen Content'), findsOneWidget);

      // Tap back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen Content'), findsOneWidget);
    });

    testWidgets('back navigation pops pushed routes back to the shell screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/detail',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Detail Screen')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('Home Screen Content')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/expenses',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('Expenses Screen Content')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/budgets',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('Budgets Screen Content')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/more',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('More Screen Content')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildShellApp(customRouter: router));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Content'), findsOneWidget);

      // Push detail route above the shell
      router.push('/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail Screen'), findsOneWidget);

      // Back navigation via pop
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      // Should return to the shell Home tab
      expect(find.text('Home Screen Content'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders in Dark Mode without layout or color issues', (tester) async {
      await tester.pumpWidget(buildShellApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Tap Expenses in dark mode
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Expenses Screen Content'), findsOneWidget);
    });

    testWidgets('renders cleanly on small screen sizes (320x480) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildShellApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });
  });
}
