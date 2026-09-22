import 'package:flutter/material.dart';

/// Stable expense categories.
///
/// `id` is the value persisted to Firestore and must NEVER change — expenses
/// keep their category forever, even when the picker order or labels are
/// tweaked later. `fromId` falls back to [ExpenseCategory.other] for unknown
/// ids so old or remote data never crashes the UI.
enum ExpenseCategory {
  rent(
    id: 'rent',
    label: 'Rent',
    icon: Icons.home_work_rounded,
    color: Color(0xFF6366F1),
  ),
  food(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF97316),
  ),
  groceries(
    id: 'groceries',
    label: 'Groceries',
    icon: Icons.shopping_cart_rounded,
    color: Color(0xFF10B981),
  ),
  electricity(
    id: 'electricity',
    label: 'Electricity',
    icon: Icons.bolt_rounded,
    color: Color(0xFFF59E0B),
  ),
  gas(
    id: 'gas',
    label: 'Gas',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFEF4444),
  ),
  water(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF06B6D4),
  ),
  internet(
    id: 'internet',
    label: 'Internet',
    icon: Icons.wifi_rounded,
    color: Color(0xFF3B82F6),
  ),
  cleaning(
    id: 'cleaning',
    label: 'Cleaning',
    icon: Icons.cleaning_services_rounded,
    color: Color(0xFF14B8A6),
  ),
  transport(
    id: 'transport',
    label: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF8B5CF6),
  ),
  household(
    id: 'household',
    label: 'Household',
    icon: Icons.weekend_rounded,
    color: Color(0xFFEC4899),
  ),
  entertainment(
    id: 'entertainment',
    label: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFA855F7),
  ),
  other(
    id: 'other',
    label: 'Other',
    icon: Icons.category_rounded,
    color: Color(0xFF64748B),
  );

  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Stable id stored in Firestore.
  final String id;

  /// Human-readable label shown in pickers and lists.
  final String label;

  /// Icon representing this category.
  final IconData icon;

  /// Signature color for category chip and chart representation.
  final Color color;

  /// Resolves a stored id back to its category, defaulting to
  /// [ExpenseCategory.other] for anything unknown. Handles legacy aliases gracefully.
  static ExpenseCategory fromId(String? id) {
    if (id == null) return ExpenseCategory.other;
    return switch (id) {
      'utilities' => ExpenseCategory.electricity,
      'diningOut' => ExpenseCategory.food,
      'furniture' => ExpenseCategory.household,
      'health' => ExpenseCategory.other,
      'subscriptions' => ExpenseCategory.internet,
      _ => values.firstWhere(
          (category) => category.id == id,
          orElse: () => ExpenseCategory.other,
        ),
    };
  }
}
