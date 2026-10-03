import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../domain/budget_repository.dart';

/// Firestore-backed implementation of [BudgetRepository].
///
/// Budget data lives on the household document itself:
///   `households/{householdId}.monthlyBudgetPaisa`
///   `households/{householdId}.categoryBudgetsPaisa`
///   `households/{householdId}.memberCategoryBudgetsPaisa`
class FirebaseBudgetRepository implements BudgetRepository {
  FirebaseBudgetRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _householdRef(String householdId) =>
      _firestore.collection(FirestoreCollections.households).doc(householdId);

  @override
  Future<int?> fetchTotalBudget({required String householdId}) async {
    final snap = await _householdRef(householdId).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    final raw = data['monthlyBudgetPaisa'];
    if (raw == null) return null;
    return (raw as num).toInt();
  }

  @override
  Future<Map<String, int>> fetchCategoryBudgets({
    required String householdId,
  }) async {
    final snap = await _householdRef(householdId).get();
    if (!snap.exists) return const {};
    final raw = snap.data()!['categoryBudgetsPaisa'];
    if (raw == null) return const {};
    return Map<String, dynamic>.from(raw as Map)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  @override
  Future<Map<String, Map<String, int>>> fetchMemberCategoryBudgets({
    required String householdId,
  }) async {
    final snap = await _householdRef(householdId).get();
    if (!snap.exists) return const {};
    final raw = snap.data()!['memberCategoryBudgetsPaisa'];
    if (raw == null) return const {};
    return Map<String, dynamic>.from(raw as Map).map(
      (catId, memberMap) => MapEntry(
        catId,
        Map<String, dynamic>.from(memberMap as Map)
            .map((uid, v) => MapEntry(uid, (v as num).toInt())),
      ),
    );
  }

  @override
  Future<void> updateTotalBudget({
    required String householdId,
    required int budgetPaisa,
  }) async {
    await _householdRef(householdId).update({
      'monthlyBudgetPaisa': budgetPaisa,
    });
  }

  @override
  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  }) async {
    final updates = <String, dynamic>{
      'categoryBudgetsPaisa': categoryBudgetsPaisa,
    };
    if (memberCategoryBudgetsPaisa.isNotEmpty) {
      updates['memberCategoryBudgetsPaisa'] = memberCategoryBudgetsPaisa;
    }
    await _householdRef(householdId).update(updates);
  }
}
