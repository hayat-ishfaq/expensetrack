import 'package:expensetrack/features/expenses/domain/custom_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomCategory', () {
    test('fromMap/toMap round-trip preserves all fields', () {
      const category = CustomCategory(
        id: 'cat_pets_999',
        label: 'Pets & Supplies',
        iconCodePoint: 0xe4a1,
        colorValue: 0xFF10B981,
        subcategories: ['Vet Visits', 'Food', 'Toys'],
      );

      final map = category.toMap();
      final restored = CustomCategory.fromMap(map);

      expect(restored.id, 'cat_pets_999');
      expect(restored.label, 'Pets & Supplies');
      expect(restored.iconCodePoint, 0xe4a1);
      expect(restored.colorValue, 0xFF10B981);
      expect(restored.subcategories, ['Vet Visits', 'Food', 'Toys']);
      expect(restored.icon, isA<IconData>());
      expect(restored.color, const Color(0xFF10B981));
    });

    test('copyWith updates properties', () {
      const category = CustomCategory(
        id: 'cat_1',
        label: 'Gym',
        iconCodePoint: 1234,
        colorValue: 0xFF6366F1,
      );

      final updated = category.copyWith(
        label: 'Fitness & Gym',
        subcategories: ['Membership', 'Supplements'],
      );

      expect(updated.id, 'cat_1');
      expect(updated.label, 'Fitness & Gym');
      expect(updated.subcategories, ['Membership', 'Supplements']);
      expect(updated.colorValue, 0xFF6366F1);
    });

    test('equality and hash code check', () {
      const cat1 = CustomCategory(
        id: 'c1',
        label: 'Gaming',
        iconCodePoint: 100,
        colorValue: 0xFF00FF00,
      );
      const cat2 = CustomCategory(
        id: 'c1',
        label: 'Gaming',
        iconCodePoint: 100,
        colorValue: 0xFF00FF00,
      );
      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
    });
  });
}
