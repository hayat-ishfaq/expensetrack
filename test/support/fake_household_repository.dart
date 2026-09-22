import 'package:expensetrack/features/household/domain/household_repository.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';

/// In-memory [HouseholdRepository] for widget tests. No Firebase involved.
class FakeHouseholdRepository implements HouseholdRepository {
  FakeHouseholdRepository({this.household, this.members = const []});

  Household? household;
  List<HouseholdMember> members;

  @override
  Stream<Household?> watchHousehold(String householdId) async* {
    yield household;
  }

  @override
  Stream<List<HouseholdMember>> watchMembers(String householdId) async* {
    yield members;
  }

  @override
  Future<Household> createHousehold({required String name}) =>
      throw UnimplementedError('Not exercised in widget tests.');

  @override
  Future<Household> joinHousehold({required String inviteCode}) =>
      throw UnimplementedError('Not exercised in widget tests.');

  @override
  Future<void> leaveHousehold() async {}

  @override
  Future<void> updateMonthlyBudget({
    required String householdId,
    required int budgetPaisa,
  }) async {
    if (household != null) {
      household = household!.copyWith(monthlyBudgetPaisa: budgetPaisa);
    }
  }

  @override
  Future<void> renameHousehold({
    required String householdId,
    required String name,
  }) async {
    if (household != null) {
      household = household!.copyWith(name: name);
    }
  }

  @override
  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  }) async {
    if (household != null) {
      household = household!.copyWith(
        categoryBudgetsPaisa: categoryBudgetsPaisa,
        memberCategoryBudgetsPaisa: memberCategoryBudgetsPaisa,
      );
    }
  }
}