import 'package:expensetrack/features/settlement/domain/settlement.dart';
import 'package:expensetrack/features/settlement/domain/settlement_repository.dart';

class FakeSettlementRepository implements SettlementRepository {
  FakeSettlementRepository({this.settlements = const []});

  List<RecordedSettlement> settlements;

  @override
  Stream<List<RecordedSettlement>> watchSettlements(String householdId) async* {
    yield settlements;
  }

  @override
  Future<void> recordSettlement({
    required String householdId,
    required SettlementTransfer transfer,
    required String recordedByUserId,
  }) async {
    settlements = [
      RecordedSettlement(
        id: 's-${settlements.length}',
        fromUserId: transfer.fromMemberId,
        toUserId: transfer.toMemberId,
        amountPaisa: transfer.amountPaisa,
        recordedByUserId: recordedByUserId,
        settledAt: DateTime(2026, 9, 30),
      ),
      ...settlements,
    ];
  }
}
