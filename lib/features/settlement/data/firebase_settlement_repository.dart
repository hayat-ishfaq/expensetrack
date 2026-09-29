import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../domain/settlement.dart';
import '../domain/settlement_repository.dart';

class FirebaseSettlementRepository implements SettlementRepository {
  FirebaseSettlementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) =>
      _firestore.collection(
        '${FirestoreCollections.households}/$householdId/${FirestoreCollections.settlements}',
      );

  RecordedSettlement _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    DateTime settledAt = DateTime.now();
    final raw = data['settledAt'];
    if (raw is Timestamp) {
      settledAt = raw.toDate();
    }
    return RecordedSettlement(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      amountPaisa: (data['amountPaisa'] as num?)?.toInt() ?? 0,
      recordedByUserId: data['recordedByUserId'] as String? ?? '',
      settledAt: settledAt,
    );
  }

  @override
  Stream<List<RecordedSettlement>> watchSettlements(String householdId) {
    return _collection(householdId)
        .orderBy('settledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> recordSettlement({
    required String householdId,
    required SettlementTransfer transfer,
    required String recordedByUserId,
  }) async {
    try {
      await _collection(householdId).add({
        'fromUserId': transfer.fromMemberId,
        'toUserId': transfer.toMemberId,
        'amountPaisa': transfer.amountPaisa,
        'recordedByUserId': recordedByUserId,
        'settledAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw toAppException(error);
    }
  }
}
