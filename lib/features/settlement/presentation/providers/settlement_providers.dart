import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../data/firebase_settlement_repository.dart';
import '../../domain/settlement.dart';
import '../../domain/settlement_engine.dart';
import '../../domain/settlement_repository.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return FirebaseSettlementRepository(FirebaseFirestore.instance);
});

final recordedSettlementsProvider =
    StreamProvider<List<RecordedSettlement>>((ref) {
  final householdId = ref.watch(sessionProvider).value?.householdId;
  if (householdId == null) return Stream.value(const []);
  return ref.watch(settlementRepositoryProvider).watchSettlements(householdId);
});

final settlementProvider = Provider<AsyncValue<Settlement>>((ref) {
  final expensesAsync = ref.watch(householdExpensesProvider);
  final membersAsync = ref.watch(householdMembersProvider);
  final recordedAsync = ref.watch(recordedSettlementsProvider);

  final expensesError = expensesAsync.error;
  final membersError = membersAsync.error;
  final recordedError = recordedAsync.error;
  if (expensesError != null) {
    return AsyncError(expensesError, StackTrace.current);
  }
  if (membersError != null) {
    return AsyncError(membersError, StackTrace.current);
  }
  if (recordedError != null) {
    return AsyncError(recordedError, StackTrace.current);
  }

  final expenses = expensesAsync.value;
  final members = membersAsync.value;
  final recorded = recordedAsync.value;
  if (expenses == null || members == null || recorded == null) {
    return const AsyncLoading();
  }

  final memberIds = members.map((member) => member.id).toSet();
  return AsyncData(
    SettlementEngine.compute(
      expenses: expenses,
      memberIds: memberIds,
      recorded: recorded,
    ),
  );
});

class SettlementActions extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> record(SettlementTransfer transfer) async {
    final householdId = ref.read(sessionProvider).value?.householdId;
    final uid = ref.read(sessionProvider).value?.user?.id;
    if (householdId == null || uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settlementRepositoryProvider).recordSettlement(
            householdId: householdId,
            transfer: transfer,
            recordedByUserId: uid,
          );
    });
  }
}

final settlementActionsProvider =
    AsyncNotifierProvider<SettlementActions, void>(SettlementActions.new);
