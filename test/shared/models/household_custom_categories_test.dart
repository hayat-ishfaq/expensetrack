import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrack/features/expenses/domain/custom_category.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Household custom categories & subcategories', () {
    test('fromMap/toMap preserves customCategories and categorySubcategories', () {
      final now = DateTime(2026, 9, 23, 10, 0);
      final household = Household(
        id: 'h_123',
        name: 'Apartment 4B',
        ownerId: 'u_1',
        inviteCode: 'FLAT-9999',
        memberCount: 3,
        monthlyBudgetPaisa: 5000000,
        currency: 'PKR',
        createdAt: now,
        customCategories: const [
          CustomCategory(
            id: 'cat_gym',
            label: 'Gym & Fitness',
            iconCodePoint: 123,
            colorValue: 0xFF6366F1,
            subcategories: ['Membership', 'Supplements'],
          ),
        ],
        categorySubcategories: const {
          'food': ['Biryani', 'Late Night Snacks'],
        },
      );

      final map = household.toMap();
      final restored = Household.fromMap('h_123', map);

      expect(restored.customCategories.length, 1);
      expect(restored.customCategories.first.id, 'cat_gym');
      expect(restored.customCategories.first.label, 'Gym & Fitness');
      expect(restored.customCategories.first.subcategories, ['Membership', 'Supplements']);
      expect(restored.categorySubcategories['food'], ['Biryani', 'Late Night Snacks']);
    });

    test('getSubcategories returns combined defaults and household subcategories', () {
      final household = Household(
        id: 'h_123',
        name: 'Apartment 4B',
        ownerId: 'u_1',
        inviteCode: 'FLAT-9999',
        memberCount: 3,
        monthlyBudgetPaisa: 5000000,
        currency: 'PKR',
        createdAt: DateTime.now(),
        customCategories: const [
          CustomCategory(
            id: 'cat_pets',
            label: 'Pets',
            iconCodePoint: 123,
            colorValue: 0xFF10B981,
            subcategories: ['Vet', 'Food'],
          ),
        ],
        categorySubcategories: const {
          'food': ['Specialty Tea'],
          'cat_pets': ['Grooming'],
        },
      );

      // Check standard category 'food'
      final foodSubcats = household.getSubcategories('food');
      expect(foodSubcats, contains('Groceries'));
      expect(foodSubcats, contains('Fast Food'));
      expect(foodSubcats, contains('Specialty Tea'));

      // Check custom category 'cat_pets'
      final petSubcats = household.getSubcategories('cat_pets');
      expect(petSubcats, contains('Vet'));
      expect(petSubcats, contains('Food'));
      expect(petSubcats, contains('Grooming'));
    });
  });
}
