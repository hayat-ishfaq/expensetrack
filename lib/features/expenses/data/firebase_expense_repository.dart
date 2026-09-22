import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) =>
      _firestore.collection(
        '${FirestoreCollections.households}/$householdId/${FirestoreCollections.expenses}',
      );

  @override
  Future<Expense> createExpense(Expense expense) async {
    try {
      final docRef = _collection(expense.householdId).doc();
      final newExpense = Expense(
        id: docRef.id,
        householdId: expense.householdId,
        description: expense.description,
        category: expense.category,
        amountPaisa: expense.amountPaisa,
        paidById: expense.paidById,
        splitAmongIds: expense.splitAmongIds,
        splitAmountsPaisa: expense.splitAmountsPaisa,
        spentAt: expense.spentAt,
        createdByUserId: expense.createdByUserId,
        createdAt: expense.createdAt,
        splitType: expense.splitType,
      );
      await docRef.set(newExpense.toMap());
      return newExpense;
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _collection(expense.householdId).doc(expense.id).set(
            expense.toMap(),
            SetOptions(merge: true),
          );
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  }) async {
    try {
      await _collection(householdId).doc(expenseId).delete();
    } catch (error) {
      throw toAppException(error);
    }
  }

  @override
  Stream<List<Expense>> watchExpenses(String householdId) {
    return _collection(householdId)
        .orderBy('spentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Expense>> watchRecentExpenses(
    String householdId, {
    int limit = 5,
  }) {
    return _collection(householdId)
        .orderBy('spentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.id, doc.data()))
            .toList());
  }
}
