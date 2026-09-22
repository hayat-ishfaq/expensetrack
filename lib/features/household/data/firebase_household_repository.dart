import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/household.dart';
import '../../../shared/models/household_member.dart';
import '../domain/household_repository.dart';
import '../domain/invite_code.dart';

/// Firestore implementation of [HouseholdRepository].
class FirebaseHouseholdRepository implements HouseholdRepository {
  FirebaseHouseholdRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static final RegExp _invitePattern = RegExp(r'^FLAT-[A-Z0-9]{4}$');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Your session ended. Please sign in again.');
    }
    return user.uid;
  }

  Future<Map<String, dynamic>> _currentUserProfile() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(_uid)
        .get();
    return snapshot.data() ?? const {};
  }

  Future<String> _uniqueInviteCode() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = InviteCode.generate(Random.secure());
      final existing = await _firestore
          .doc('${FirestoreCollections.inviteCodes}/$code')
          .get();
      if (!existing.exists) return code;
    }
    throw const HouseholdException(
      "Couldn't find a free invite code. Please try again.",
    );
  }

  @override
  Future<Household> createHousehold({required String name}) async {
    try {
      final uid = _uid;
      final profile = await _currentUserProfile();
      final code = await _uniqueInviteCode();
      final householdRef =
          _firestore.collection(FirestoreCollections.households).doc();
      final now = DateTime.now();

      final household = Household(
        id: householdRef.id,
        name: name.trim(),
        ownerId: uid,
        inviteCode: code,
        memberCount: 1,
        monthlyBudgetPaisa: 0,
        currency: AppConstants.defaultCurrency,
        createdAt: now,
      );

      final member = HouseholdMember(
        id: uid,
        name: profile['name'] as String? ?? 'FlatOwner',
        email: profile['email'] as String? ?? '',
        photoUrl: profile['photoUrl'] as String?,
        role: MemberRole.owner,
        joinedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(householdRef, household.toMap());
      batch.set(
        _firestore
            .doc('${FirestoreCollections.inviteCodes}/$code'),
        {
          'householdId': household.id,
          'createdAt': Timestamp.fromDate(now),
        },
      );
      batch.set(
        householdRef
            .collection(FirestoreCollections.members)
            .doc(uid),
        member.toMap(),
      );
      batch.set(
        _firestore.collection(FirestoreCollections.users).doc(uid),
        {'householdId': household.id},
        SetOptions(merge: true),
      );
      await batch.commit();
      return household;
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<Household> joinHousehold({required String inviteCode}) async {
    try {
      final uid = _uid;
      final code = Validators.normalizeInviteCode(inviteCode);
      if (!_invitePattern.hasMatch(code)) {
        throw const HouseholdException(
          'That invite code looks wrong — codes look like FLAT-7K29.',
        );
      }

      final codeSnapshot =
          await _firestore.doc('${FirestoreCollections.inviteCodes}/$code')
              .get();
      if (!codeSnapshot.exists) {
        throw const HouseholdException(
          "That invite code doesn't match any flat. "
          'Double-check it with whoever shared it.',
        );
      }

      final householdId = codeSnapshot.data()!['householdId'] as String;
      final householdRef = _firestore
          .collection(FirestoreCollections.households)
          .doc(householdId);
      final householdSnapshot = await householdRef.get();
      if (!householdSnapshot.exists) throw const NotFoundException();
      final household = Household.fromMap(
        householdId,
        householdSnapshot.data()!,
      );

      final profile = await _currentUserProfile();
      final now = DateTime.now();
      final member = HouseholdMember(
        id: uid,
        name: profile['name'] as String? ?? 'Flatmate',
        email: profile['email'] as String? ?? '',
        photoUrl: profile['photoUrl'] as String?,
        role: MemberRole.member,
        joinedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(
        householdRef.collection(FirestoreCollections.members).doc(uid),
        member.toMap(),
      );
      batch.update(householdRef, {
        'memberCount': FieldValue.increment(1),
      });
      batch.set(
        _firestore.collection(FirestoreCollections.users).doc(uid),
        {'householdId': householdId},
        SetOptions(merge: true),
      );
      await batch.commit();
      return household;
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Stream<Household?> watchHousehold(String householdId) => _firestore
      .doc('${FirestoreCollections.households}/$householdId')
      .snapshots()
      .map((snapshot) => snapshot.exists
          ? Household.fromMap(snapshot.id, snapshot.data()!)
          : null);

  @override
  Stream<List<HouseholdMember>> watchMembers(String householdId) => _firestore
      .collection(
        '${FirestoreCollections.households}/'
        '$householdId/${FirestoreCollections.members}',
      )
      .orderBy('joinedAt')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => HouseholdMember.fromMap(doc.id, doc.data()))
          .toList());

  @override
  Future<void> leaveHousehold() async {
    try {
      final uid = _uid;
      final userSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();
      final householdId = userSnapshot.data()?['householdId'] as String?;
      if (householdId == null) return;

      final batch = _firestore.batch();
      batch.delete(_firestore
          .collection(FirestoreCollections.households)
          .doc(householdId)
          .collection(FirestoreCollections.members)
          .doc(uid));
      batch.update(
        _firestore
            .collection(FirestoreCollections.households)
            .doc(householdId),
        {'memberCount': FieldValue.increment(-1)},
      );
      batch.set(
        _firestore.collection(FirestoreCollections.users).doc(uid),
        {'householdId': FieldValue.delete()},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> updateMonthlyBudget({
    required String householdId,
    required int budgetPaisa,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.households)
          .doc(householdId)
          .update({'monthlyBudgetPaisa': budgetPaisa});
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> renameHousehold({
    required String householdId,
    required String name,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.households)
          .doc(householdId)
          .update({'name': name.trim()});
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.households)
          .doc(householdId)
          .update({
        'categoryBudgetsPaisa': categoryBudgetsPaisa,
        'memberCategoryBudgetsPaisa': memberCategoryBudgetsPaisa,
      });
    } catch (error) {
      throw toAppException(error);
    }
  }
}