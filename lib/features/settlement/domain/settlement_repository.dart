import 'settlement.dart';

abstract interface class SettlementRepository {
  Stream<List<RecordedSettlement>> watchSettlements(String householdId);

  Future<void> recordSettlement({
    required String householdId,
    required SettlementTransfer transfer,
    required String recordedByUserId,
  });
}
