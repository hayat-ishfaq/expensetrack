import '../../../shared/models/household.dart';
import '../../../shared/models/household_member.dart';

/// Household ("flat") boundary. Creates/joins households and streams household
/// data; the Firebase implementation is replaced with fakes in tests.
abstract interface class HouseholdRepository {
  /// Creates a household owned by the current user, provisions the invite
  /// code and joins the user as its first member.
  Future<Household> createHousehold({required String name});

  /// Joins the household behind an invite code (e.g. `FLAT-7K29`), adding the
  /// current user as a member. Throws [HouseholdException] for unknown codes.
  Future<Household> joinHousehold({required String inviteCode});

  /// Streams the household document; emits null when it doesn't exist.
  Stream<Household?> watchHousehold(String householdId);

  /// Streams the household's members, oldest first.
  Stream<List<HouseholdMember>> watchMembers(String householdId);

  /// Leaves the current household, removing the user from its member list and
  /// clearing `users/{uid}.householdId`.
  Future<void> leaveHousehold();

  /// Updates the household's monthly budget in paisa.
  Future<void> updateMonthlyBudget({
    required String householdId,
    required int budgetPaisa,
  });

  /// Renames the household.
  Future<void> renameHousehold({
    required String householdId,
    required String name,
  });

  /// Updates the category budgets and optional per-member divisions for [householdId].
  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  });
}