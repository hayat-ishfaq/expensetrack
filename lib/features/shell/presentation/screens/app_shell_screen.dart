import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_system.dart';

/// Navigation destination model for the CoSpend shell.
class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Root scaffold for the authenticated area: a compact, modern, fintech bottom
/// navigation shell supporting 4 core destinations (Home / Expenses / Budgets / More).
class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavDestination(
      label: 'Budgets',
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
    ),
    _NavDestination(
      label: 'More',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      body: navigationShell,
      bottomNavigationBar: _CoSpendBottomNav(
        currentIndex: navigationShell.currentIndex,
        isDark: isDark,
        destinations: _destinations,
        onTap: (index) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

/// Compact, elegant, animated fintech bottom navigation bar.
class _CoSpendBottomNav extends StatelessWidget {
  const _CoSpendBottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.destinations,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = math.max(bottomInset, 8.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: !isDark
            ? const [
                BoxShadow(
                  color: Color(0x080A2542),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.only(
                top: 6,
                bottom: bottomPadding,
                left: 8,
                right: 8,
              ),
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final isSelected = index == currentIndex;
                  final item = destinations[index];

                  return Expanded(
                    child: _NavItem(
                      destination: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual animated navigation tab item with haptic touch and pill feedback.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = CoSpendColors.jadeGreen;
    final inactiveColor =
        isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle;
    final activeTextColor =
        isDark ? Colors.white : CoSpendColors.prussianBlue;

    return Semantics(
      label: '${destination.label} tab',
      selected: isSelected,
      button: true,
      container: true,
      child: BouncingButton(
        scale: 0.94,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container with soft pill backdrop
              AnimatedContainer(
                duration: CoSpendAnimations.fast,
                curve: CoSpendAnimations.curveEntrance,
                height: 32,
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? activeColor.withValues(alpha: 0.18)
                          : CoSpendColors.jadeGreenTint)
                      : Colors.transparent,
                  borderRadius: CoSpendRadii.pillRadius,
                ),
                alignment: Alignment.center,
                child: AnimatedScale(
                  duration: CoSpendAnimations.fast,
                  scale: isSelected ? 1.05 : 1.0,
                  curve: CoSpendAnimations.curveEntrance,
                  child: Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Animated label
              AnimatedDefaultTextStyle(
                duration: CoSpendAnimations.fast,
                curve: CoSpendAnimations.curveEntrance,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isSelected ? -0.2 : 0.0,
                  color: isSelected ? activeTextColor : inactiveColor,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}