import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/household.dart';
import '../../../shared/models/household_member.dart';
import '../../household/domain/invite_code.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Firestore + Firebase Auth implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static AuthUser _toAuthUser(User user) => AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

  @override
  Stream<AuthUser?> authStateChanges() => _auth
      .authStateChanges()
      .map((user) => user == null ? null : _toAuthUser(user));

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAuthUser(credential.user!);
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}

      final now = DateTime.now();
      final code = InviteCode.generate(Random.secure());
      final householdRef =
          _firestore.collection(FirestoreCollections.households).doc();
      final firstName = name.trim().split(' ').first;
      final flatName = "$firstName's Flat";

      final household = Household(
        id: householdRef.id,
        name: flatName,
        ownerId: user.uid,
        inviteCode: code,
        memberCount: 1,
        monthlyBudgetPaisa: 0,
        currency: AppConstants.defaultCurrency,
        createdAt: now,
      );

      final member = HouseholdMember(
        id: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: MemberRole.owner,
        joinedAt: now,
      );

      final appUser = AppUser(
        id: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        householdId: household.id,
        createdAt: now,
      );

      final batch = _firestore.batch();
      batch.set(
        _firestore.collection(FirestoreCollections.users).doc(user.uid),
        appUser.toMap(),
      );
      batch.set(householdRef, household.toMap());
      batch.set(
        _firestore.doc('${FirestoreCollections.inviteCodes}/$code'),
        {
          'householdId': household.id,
          'createdAt': Timestamp.fromDate(now),
        },
      );
      batch.set(
        householdRef.collection(FirestoreCollections.members).doc(user.uid),
        member.toMap(),
      );
      await batch.commit();

      return appUser;
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Stream<AppUser?> watchCurrentUser(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .snapshots()
      .map((snapshot) =>
          snapshot.exists ? AppUser.fromMap(uid, snapshot.data()!) : null);

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? photoUrl,
    String? phone,
    String? upiId,
    String? bio,
    String? householdId,
  }) async {
    try {
      final trimmedName = name.trim();
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(trimmedName);
          if (photoUrl != null && photoUrl.startsWith('http')) {
            await user.updatePhotoURL(photoUrl);
          } else if (photoUrl == null || photoUrl.isEmpty) {
            await user.updatePhotoURL(null);
          }
        } catch (_) {}
      }

      final userUpdates = <String, dynamic>{
        'name': trimmedName,
        'photoUrl': photoUrl,
        'phone': phone?.trim(),
        'upiId': upiId?.trim(),
        'bio': bio?.trim(),
      };

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(userUpdates, SetOptions(merge: true));

      if (householdId != null && householdId.isNotEmpty) {
        try {
          final memberUpdates = <String, dynamic>{
            'name': trimmedName,
            'photoUrl': photoUrl,
            if (phone != null) 'phone': phone.trim(),
            if (upiId != null) 'upiId': upiId.trim(),
          };
          await _firestore
              .collection(FirestoreCollections.households)
              .doc(householdId)
              .collection(FirestoreCollections.members)
              .doc(uid)
              .set(memberUpdates, SetOptions(merge: true));
        } catch (_) {
          // Member document update failure is non-fatal if user left or doc doesn't exist
        }
      }
    } catch (error) {
      throw toAppException(error);
    }
  }
}