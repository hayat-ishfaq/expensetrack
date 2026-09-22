import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/settlement.dart';
import '../../domain/settlement_engine.dart';

/// The current household's settlement, recomputed whenever expenses or
/// members change. Surfaces load/error/data states exactly like the stream
/// providers it is built from.
final settlementProvider = Provider<AsyncValue<Settlement>>((ref) {
  final expensesAsync = ref.watch(householdExpensesProvider);
  final membersAsync = ref.watch(householdMembersProvider);

  final expensesError = expensesAsync.error;
  final membersError = membersAsync.error;
  if (expensesError != null) {
    return AsyncError(expensesError, StackTrace.current);
  }
  if (membersError != null) {
    return AsyncError(membersError, StackTrace.current);
  }

  final expenses = expensesAsync.value;
  final members = membersAsync.value;
  if (expenses == null || members == null) {
    return const AsyncLoading();
  }

  final memberIds = members.map((member) => member.id).toSet();
  return AsyncData(
    SettlementEngine.compute(expenses: expenses, memberIds: memberIds),
  );
});