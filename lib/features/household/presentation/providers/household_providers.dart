import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/fcm_service.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/custom_category.dart';
import '../../data/firebase_household_repository.dart';
import '../../domain/household_repository.dart';

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
  void build() {}

  HouseholdRepository get _repository =>
      ref.read(householdRepositoryProvider);

  Future<void> create({required String name}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final household = await _repository.createHousehold(name: name);
      ref.invalidate(currentUserProvider);
      ref.invalidate(sessionProvider);
      // Subscribe this device to the household's FCM topic so it receives
      // push notifications for new expenses, settlements, and member activity.
      FcmService.instance
          .subscribeToHousehold(household.id)
          .catchError((_) {}); // Non-fatal — don't block navigation
    });
  }

  Future<void> join({required String inviteCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Unsubscribe from any previous household topic before joining a new one.
      final oldHouseholdId = ref.read(sessionProvider).value?.householdId;
      if (oldHouseholdId != null && oldHouseholdId.isNotEmpty) {
        FcmService.instance
            .unsubscribeFromHousehold(oldHouseholdId)
            .catchError((_) {});
      }
      final household = await _repository.joinHousehold(inviteCode: inviteCode);
      ref.invalidate(currentUserProvider);
      ref.invalidate(sessionProvider);
      // Subscribe to the new household topic.
      FcmService.instance
          .subscribeToHousehold(household.id)
          .catchError((_) {});
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
      // Capture the household ID BEFORE the Firestore leave clears it.
      final householdId = ref.read(sessionProvider).value?.householdId;
      await _repository.leaveHousehold();
      // Unsubscribe from the FCM topic so this device stops receiving
      // push notifications for the household it just left.
      if (householdId != null && householdId.isNotEmpty) {
        FcmService.instance
            .unsubscribeFromHousehold(householdId)
            .catchError((_) {});
      }
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