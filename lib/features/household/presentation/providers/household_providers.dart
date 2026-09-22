import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../data/firebase_household_repository.dart';
import '../../domain/household_repository.dart';
import '../../expenses/domain/custom_category.dart';

/// Composition root for the household feature. Overridden in tests.
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return FirebaseHouseholdRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

/// Streams the signed-in user's household document.
final currentHouseholdProvider = StreamProvider<Household?>((ref) {
  final householdId = ref.watch(sessionProvider).value?.householdId;
  if (householdId == null) return Stream.value(null);
  return ref
      .watch(householdRepositoryProvider)
      .watchHousehold(householdId);
});

/// Streams the current household's members.
final householdMembersProvider = StreamProvider<List<HouseholdMember>>((ref) {
  final householdId = ref.watch(sessionProvider).value?.householdId;
  if (householdId == null) return Stream.value(const []);
  return ref
      .watch(householdRepositoryProvider)
      .watchMembers(householdId);
});

/// One-shot household commands (create / join). Screens watch this for
/// loading state and surface mapped errors.
class HouseholdActions extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  HouseholdRepository get _repository =>
      ref.read(householdRepositoryProvider);

  Future<void> create({required String name}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.createHousehold(name: name);
    });
  }

  Future<void> join({required String inviteCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.joinHousehold(inviteCode: inviteCode);
    });
  }

  Future<void> updateBudget({
    required String householdId,
    required int budgetPaisa,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateMonthlyBudget(
        householdId: householdId,
        budgetPaisa: budgetPaisa,
      );
    });
  }

  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateCategoryBudgets(
        householdId: householdId,
        categoryBudgetsPaisa: categoryBudgetsPaisa,
        memberCategoryBudgetsPaisa: memberCategoryBudgetsPaisa,
      );
    });
  }

  Future<void> rename({
    required String householdId,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.renameHousehold(
        householdId: householdId,
        name: name,
      );
    });
  }

  Future<void> leave() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.leaveHousehold();
    });
  }

  Future<void> addCustomCategory({
    required String householdId,
    required CustomCategory category,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.addCustomCategory(
        householdId: householdId,
        category: category,
      );
    });
  }

  Future<void> addSubcategory({
    required String householdId,
    required String categoryId,
    required String subcategory,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.addSubcategory(
        householdId: householdId,
        categoryId: categoryId,
        subcategory: subcategory,
      );
    });
  }
}

final householdActionsProvider =
    AsyncNotifierProvider<HouseholdActions, void>(HouseholdActions.new);