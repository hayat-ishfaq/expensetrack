import 'package:flutter/material.dart';

/// Presentation data model representing a category item within the budget hub.
class BudgetCategoryItem {
  const BudgetCategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isCustom;
}
