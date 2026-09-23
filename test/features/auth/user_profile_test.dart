import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    test('serializes and deserializes all profile fields correctly', () {
      final now = DateTime(2026, 9, 23, 14, 0);
      final user = AppUser(
        id: 'u1',
        name: 'Hamza Khan',
        email: 'hamza@example.com',
        photoUrl: 'avatar:techie',
        phone: '+92 300 1234567',
        upiId: 'hamza@okhdfcbank',
        bio: 'Room 204 • Techie',
        householdId: 'h1',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['id'], 'u1');
      expect(map['name'], 'Hamza Khan');
      expect(map['email'], 'hamza@example.com');
      expect(map['photoUrl'], 'avatar:techie');
      expect(map['phone'], '+92 300 1234567');
      expect(map['upiId'], 'hamza@okhdfcbank');
      expect(map['bio'], 'Room 204 • Techie');
      expect(map['householdId'], 'h1');
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = AppUser.fromMap('u1', map);
      expect(deserialized.id, user.id);
      expect(deserialized.name, user.name);
      expect(deserialized.email, user.email);
      expect(deserialized.photoUrl, user.photoUrl);
      expect(deserialized.phone, user.phone);
      expect(deserialized.upiId, user.upiId);
      expect(deserialized.bio, user.bio);
      expect(deserialized.householdId, user.householdId);
    });

    test('copyWith updates profile fields correctly', () {
      final user = AppUser(
        id: 'u1',
        name: 'Hamza',
        email: 'hamza@example.com',
        createdAt: DateTime.now(),
      );

      final updated = user.copyWith(
        name: 'Hamza Khan',
        photoUrl: 'avatar:chef',
        phone: '+92 300 0000000',
        upiId: 'hamza@upi',
        bio: 'Flat Chef',
      );

      expect(updated.name, 'Hamza Khan');
      expect(updated.photoUrl, 'avatar:chef');
      expect(updated.phone, '+92 300 0000000');
      expect(updated.upiId, 'hamza@upi');
      expect(updated.bio, 'Flat Chef');
      expect(updated.email, 'hamza@example.com');
    });
  });

  group('HouseholdMember', () {
    test('supports phone and upiId serialization', () {
      final now = DateTime(2026, 9, 23, 14, 0);
      final member = HouseholdMember(
        id: 'u1',
        name: 'Bilal',
        email: 'bilal@example.com',
        photoUrl: 'avatar:coffee',
        phone: '+92 321 9876543',
        upiId: 'bilal@upi',
        role: MemberRole.owner,
        joinedAt: now,
      );

      final map = member.toMap();
      expect(map['phone'], '+92 321 9876543');
      expect(map['upiId'], 'bilal@upi');
      expect(map['photoUrl'], 'avatar:coffee');

      final deserialized = HouseholdMember.fromMap('u1', map);
      expect(deserialized.phone, '+92 321 9876543');
      expect(deserialized.upiId, 'bilal@upi');
      expect(deserialized.photoUrl, 'avatar:coffee');
    });
  });
}
