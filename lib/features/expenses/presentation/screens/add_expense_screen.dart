import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/custom_category.dart';
import '../../domain/expense.dart';
import '../../domain/expense_category.dart';
import '../../domain/split_modes.dart';
import '../providers/expense_providers.dart';
import '../widgets/create_category_sheet.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  CustomCategory? _selectedCustomCategory;
  String? _selectedSubcategory;
  DateTime _spentAt = DateTime.now();
  String? _paidById;
  SplitMode _splitMode = SplitMode.equal;

  // Selected participant IDs for equal split
  final Set<String> _selectedMemberIds = {};

  // Controllers for custom amount inputs
  final Map<String, TextEditingController> _customControllers = {};

  // Controllers for percentage inputs
  final Map<String, TextEditingController> _percentageControllers = {};

  bool _initializedMembers = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _descriptionController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _descriptionController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    for (final controller in _customControllers.values) {
      controller.dispose();
    }
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _initMembersIfNeeded(List<HouseholdMember> members) {
    if (_initializedMembers || members.isEmpty) return;
    _initializedMembers = true;

    final currentUid = ref.read(sessionProvider).value?.user?.id;
    _paidById = members.any((m) => m.id == currentUid)
        ? currentUid
        : members.first.id;

    _selectedMemberIds.addAll(members.map((m) => m.id));

    // Initialize custom & percentage controllers
    final equalPercent = (100.0 / members.length).toStringAsFixed(1);
    for (final m in members) {
      final customCtrl = TextEditingController();
      customCtrl.addListener(() => setState(() {}));
      _customControllers[m.id] = customCtrl;

      final pctCtrl = TextEditingController(text: equalPercent);
      pctCtrl.addListener(() => setState(() {}));
      _percentageControllers[m.id] = pctCtrl;
    }
  }

  int get _amountPaisa => Money.tryParsePaisa(_amountController.text) ?? 0;

  String? _validateSplits(List<HouseholdMember> members) {
    if (_amountPaisa <= 0) return 'Enter an expense amount greater than zero.';
    if (_paidById == null) return 'Select who paid for this expense.';

    switch (_splitMode) {
      case SplitMode.equal:
        if (_selectedMemberIds.isEmpty) {
          return 'Select at least one member to split with.';
        }
        return null;

      case SplitMode.custom:
        final shares = members.map((m) {
          final text = _customControllers[m.id]?.text ?? '0';
          return Money.tryParsePaisa(text) ?? 0;
        }).toList();
        return SplitHelper.validateCustomShares(
          totalPaisa: _amountPaisa,
          sharesPaisa: shares,
        );

      case SplitMode.percentage:
        final percentages = members.map((m) {
          final text = _percentageControllers[m.id]?.text ?? '0';
          return double.tryParse(text) ?? 0.0;
        }).toList();
        return SplitHelper.validatePercentages(
          totalPaisa: _amountPaisa,
          percentages: percentages,
        );
    }
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: CoSpendColors.jadeGreen,
                    surface: CoSpendColors.darkCard,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: CoSpendColors.prussianBlue,
                    surface: Colors.white,
                    onSurface: CoSpendColors.prussianBlue,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _spentAt = picked);
    }
  }

  Future<void> _promptAddSubcategory(String categoryId) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newSubcat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? CoSpendColors.darkCard : Colors.white,
        title: Text(
          'Add Subcategory',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Chai, Snacks, Internet',
            hintStyle: TextStyle(
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
            ),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CoSpendColors.jadeGreen,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newSubcat != null && newSubcat.isNotEmpty) {
      final household = ref.read(currentHouseholdProvider).value;
      if (household != null) {
        ref.read(householdActionsProvider.notifier).addSubcategory(
              householdId: household.id,
              categoryId: categoryId,
              subcategory: newSubcat,
            );
      }
      setState(() => _selectedSubcategory = newSubcat);
      HapticFeedback.selectionClick();
    }
  }

  void _showCategoryPicker() {
    final household = ref.read(currentHouseholdProvider).value;
    final customCategories = household?.customCategories ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? CoSpendColors.darkCanvas : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: CoSpendRadii.modalTopRadius,
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? CoSpendColors.darkBorder : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      BouncingButton(
                        scale: 0.95,
                        onTap: () async {
                          Navigator.of(context).pop();
                          final created = await CreateCategorySheet.show(context);
                          if (created != null && mounted) {
                            setState(() {
                              _selectedCustomCategory = created;
                              _category = ExpenseCategory.other;
                              _selectedSubcategory = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? CoSpendColors.darkCard : CoSpendColors.surfaceMuted,
                            borderRadius: CoSpendRadii.pillRadius,
                            border: Border.all(
                              color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: isDark ? Colors.white : CoSpendColors.prussianBlue),
                              const SizedBox(width: 4),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (customCategories.isNotEmpty) ...[
                          Text(
                            'HOUSEHOLD CUSTOM CATEGORIES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.05,
                            ),
                            itemCount: customCategories.length,
                            itemBuilder: (context, index) {
                              final cat = customCategories[index];
                              final isSelected = _selectedCustomCategory?.id == cat.id;
                              return _CategoryTileItem(
                                label: cat.label,
                                icon: cat.icon,
                                color: cat.color,
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () {
                                  setState(() {
                                    _selectedCustomCategory = cat;
                                    _category = ExpenseCategory.other;
                                    _selectedSubcategory = null;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          'STANDARD CATEGORIES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: ExpenseCategory.values.length,
                          itemBuilder: (context, index) {
                            final cat = ExpenseCategory.values[index];
                            final isSelected = _selectedCustomCategory == null && cat == _category;
                            return _CategoryTileItem(
                              label: cat.label,
                              icon: cat.icon,
                              color: cat.color,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () {
                                setState(() {
                                  _category = cat;
                                  _selectedCustomCategory = null;
                                  _selectedSubcategory = null;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPayerPicker(List<HouseholdMember> members) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? CoSpendColors.darkCanvas : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: CoSpendRadii.modalTopRadius,
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? CoSpendColors.darkBorder : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Who Paid?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final member in members)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _paidById == member.id
                          ? CoSpendColors.jadeGreen
                          : (isDark ? CoSpendColors.darkCard : const Color(0x140A2542)),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: _paidById == member.id
                              ? Colors.white
                              : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    subtitle: Text(
                      member.email,
                      style: TextStyle(
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: _paidById == member.id
                        ? const Icon(Icons.check_circle_rounded, color: CoSpendColors.jadeGreen, size: 22)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _paidById = member.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(List<HouseholdMember> members) async {
    if (!_formKey.currentState!.validate()) return;

    final splitError = _validateSplits(members);
    if (splitError != null) {
      showAppSnack(context, splitError, error: true);
      return;
    }

    final session = ref.read(sessionProvider).value;
    final household = ref.read(currentHouseholdProvider).value;
    final householdId = session?.householdId ?? household?.id;
    final currentUid = session?.user?.id ?? _paidById ?? (members.isNotEmpty ? members.first.id : null);
    if (householdId == null || currentUid == null) {
      showAppSnack(context, 'Missing flat session.', error: true);
      return;
    }

    List<String> splitAmongIds = [];
    List<int> splitAmountsPaisa = [];

    switch (_splitMode) {
      case SplitMode.equal:
        splitAmongIds = _selectedMemberIds.toList();
        splitAmountsPaisa = SplitHelper.computeEqualShares(
          _amountPaisa,
          splitAmongIds.length,
        );
        break;

      case SplitMode.custom:
        for (final m in members) {
          final amt = Money.tryParsePaisa(_customControllers[m.id]?.text) ?? 0;
          if (amt > 0) {
            splitAmongIds.add(m.id);
            splitAmountsPaisa.add(amt);
          }
        }
        break;

      case SplitMode.percentage:
        final activeMembers = <HouseholdMember>[];
        final pcts = <double>[];
        for (final m in members) {
          final pct = double.tryParse(_percentageControllers[m.id]?.text ?? '') ?? 0.0;
          if (pct > 0) {
            activeMembers.add(m);
            pcts.add(pct);
          }
        }
        splitAmongIds = activeMembers.map((m) => m.id).toList();
        splitAmountsPaisa = SplitHelper.computePercentageShares(
          totalPaisa: _amountPaisa,
          percentages: pcts,
        );
        break;
    }

    final expense = Expense(
      id: '',
      householdId: householdId,
      description: _descriptionController.text.trim(),
      category: _category,
      customCategoryId: _selectedCustomCategory?.id,
      subcategory: _selectedSubcategory,
      amountPaisa: _amountPaisa,
      paidById: _paidById!,
      splitAmongIds: splitAmongIds,
      splitAmountsPaisa: splitAmountsPaisa,
      spentAt: _spentAt,
      createdByUserId: currentUid,
      createdAt: DateTime.now(),
      splitType: _splitMode.name,
    );

    HapticFeedback.mediumImpact();
    await ref.read(expenseActionsProvider.notifier).addExpense(expense);

    final actionState = ref.read(expenseActionsProvider);
    if (!mounted) return;

    if (actionState.hasError) {
      final err = actionState.error!;
      final message = err is AppException ? err.message : FirebaseErrorMapper.messageFor(err);
      showAppSnack(context, message, error: true);
    } else {
      // Trigger subtle success state
      setState(() => _isSuccess = true);
      HapticFeedback.lightImpact();
      showAppSnack(context, 'Expense added successfully.');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        try {
          context.pop();
        } catch (_) {
          Navigator.of(context).maybePop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final membersAsync = ref.watch(householdMembersProvider);
    final isSaving = ref.watch(expenseActionsProvider).isLoading;
    ref.watch(sessionProvider);
    ref.watch(currentHouseholdProvider);

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
        centerTitle: false,
      ),
      body: membersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CoSpendColors.jadeGreen),
        ),
        error: (error, _) => Center(
          child: Text(
            FirebaseErrorMapper.messageFor(error),
            style: TextStyle(color: isDark ? Colors.white : CoSpendColors.prussianBlue),
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Text(
                'No household members found.',
                style: TextStyle(color: isDark ? Colors.white : CoSpendColors.prussianBlue),
              ),
            );
          }
          _initMembersIfNeeded(members);

          final payer = members.firstWhere(
            (m) => m.id == _paidById,
            orElse: () => members.first,
          );

          final splitValidationError = _validateSplits(members);
          final isFormValid = _amountPaisa > 0 &&
              _descriptionController.text.trim().isNotEmpty &&
              splitValidationError == null;

          return Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // 1. VISUAL AMOUNT HERO (Dominating typography)
                _buildAmountHero(isDark),
                const SizedBox(height: 16),

                // 2. DESCRIPTION FIELD
                _buildDescriptionField(isDark),
                const SizedBox(height: 12),

                // 3. CATEGORY & DATE IN A ROW
                _buildCategoryAndDateRow(isDark),
                const SizedBox(height: 12),

                // 4. SUBCATEGORY SECTION
                _buildSubcategorySection(isDark),
                const SizedBox(height: 12),

                // 5. PAID BY SELECTOR CARD
                _buildPaidByCard(isDark, payer, members),
                const SizedBox(height: 18),

                // 6. SPLIT HEADER & SEGMENTED MODE CONTROL
                _buildSplitHeader(isDark),
                const SizedBox(height: 10),

                CoSpendSegmentedControl<SplitMode>(
                  selected: _splitMode,
                  items: const {
                    SplitMode.equal: 'Equal',
                    SplitMode.custom: 'Exact',
                    SplitMode.percentage: '%',
                  },
                  onChanged: (mode) {
                    HapticFeedback.selectionClick();
                    setState(() => _splitMode = mode);
                  },
                ),
                const SizedBox(height: 12),

                // Split Validation Alert
                if (splitValidationError != null && _amountPaisa > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CoSpendColors.alertRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoSpendColors.alertRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: CoSpendColors.alertRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            splitValidationError,
                            style: const TextStyle(
                              color: CoSpendColors.alertRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 7. PARTICIPANT LIST PER MODE
                _buildSplitSection(isDark, members),
                const SizedBox(height: 24),

                // 8. PRIMARY CTA (Save / Add Expense)
                _buildSaveButton(isFormValid, isSaving, members, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. AMOUNT HERO
  // ===========================================================================

  Widget _buildAmountHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : Colors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
        ),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW MUCH WAS SPENT?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rs.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? CoSpendColors.jadeGreen : CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Expense amount in Pakistani Rupees',
                  child: TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: isDark ? CoSpendColors.darkBorder : const Color(0xFFD1D5DB),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: Validators.amount,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DESCRIPTION FIELD
  // ===========================================================================

  Widget _buildDescriptionField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : Colors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
        ),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: TextFormField(
        controller: _descriptionController,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
        ),
        decoration: InputDecoration(
          hintText: 'What is this for? (e.g. Groceries, Dinner)',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
          ),
          prefixIcon: Icon(
            Icons.receipt_outlined,
            size: 20,
            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.prussianBlue,
          ),
          suffixIcon: _descriptionController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear description',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _descriptionController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
        ),
        validator: Validators.description,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ===========================================================================
  // 3. CATEGORY & DATE IN A ROW
  // ===========================================================================

  Widget _buildCategoryAndDateRow(bool isDark) {
    final activeCatLabel = _selectedCustomCategory?.label ?? _category.label;
    final activeCatIcon = _selectedCustomCategory?.icon ?? _category.icon;
    final activeCatColor = _selectedCustomCategory?.color ?? _category.color;

    return Row(
      children: [
        // Category Selector Card
        Expanded(
          child: Semantics(
            button: true,
            label: 'Category: $activeCatLabel. Tap to change category',
            child: BouncingButton(
              scale: 0.97,
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkCard : Colors.white,
                  borderRadius: CoSpendRadii.cardRadius,
                  border: Border.all(
                    color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  ),
                  boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: activeCatColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(activeCatIcon, color: activeCatColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CATEGORY',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeCatLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? CoSpendColors.darkTextMuted : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Date Selector Card
        Expanded(
          child: Semantics(
            button: true,
            label: 'Expense date: ${DateFormat('dd MMMM yyyy').format(_spentAt)}. Tap to change date',
            child: BouncingButton(
              scale: 0.97,
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkCard : Colors.white,
                  borderRadius: CoSpendRadii.cardRadius,
                  border: Border.all(
                    color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  ),
                  boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: CoSpendColors.prussianBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.calendar_today_rounded, color: CoSpendColors.prussianBlue, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy').format(_spentAt),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? CoSpendColors.darkTextMuted : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. SUBCATEGORY SECTION
  // ===========================================================================

  Widget _buildSubcategorySection(bool isDark) {
    final activeCatId = _selectedCustomCategory?.id ?? _category.id;
    final household = ref.watch(currentHouseholdProvider).value;
    final availableSubcats = household?.getSubcategories(activeCatId) ??
        defaultCategorySubcategories[activeCatId] ??
        const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SUBCATEGORY (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
              ),
            ),
            if (_selectedSubcategory != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSubcategory = null);
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: CoSpendColors.alertRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final subcat in availableSubcats) ...[
                _SubcatChip(
                  label: subcat,
                  isSelected: _selectedSubcategory == subcat,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSubcategory = _selectedSubcategory == subcat ? null : subcat;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              BouncingButton(
                scale: 0.95,
                onTap: () => _promptAddSubcategory(activeCatId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? CoSpendColors.darkCard : Colors.white,
                    borderRadius: CoSpendRadii.pillRadius,
                    border: Border.all(
                      color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: isDark ? Colors.white : CoSpendColors.prussianBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Add Subcategory',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. PAID BY SELECTOR CARD
  // ===========================================================================

  Widget _buildPaidByCard(bool isDark, HouseholdMember payer, List<HouseholdMember> members) {
    return Semantics(
      button: true,
      label: 'Paid by: ${payer.name}. Tap to change payer',
      child: BouncingButton(
        scale: 0.98,
        onTap: () => _showPayerPicker(members),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : Colors.white,
          borderRadius: CoSpendRadii.cardRadius,
          border: Border.all(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
          boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: CoSpendColors.prussianBlue,
              child: Text(
                payer.name.isNotEmpty ? payer.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAID BY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payer.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : const Color(0x280A2542),
                ),
                borderRadius: CoSpendRadii.pillRadius,
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ===========================================================================
  // 6. SPLIT HEADER
  // ===========================================================================

  Widget _buildSplitHeader(bool isDark) {
    final perPersonAmount = (_splitMode == SplitMode.equal && _selectedMemberIds.isNotEmpty)
        ? _amountPaisa ~/ _selectedMemberIds.length
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SPLIT EXPENSE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
          ),
        ),
        if (_splitMode == SplitMode.equal && _selectedMemberIds.isNotEmpty && perPersonAmount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
              borderRadius: CoSpendRadii.pillRadius,
            ),
            child: Text(
              '${Money.format(perPersonAmount)} / person',
              style: const TextStyle(
                color: CoSpendColors.jadeGreen,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // 7. PARTICIPANT LIST PER MODE
  // ===========================================================================

  Widget _buildSplitSection(bool isDark, List<HouseholdMember> members) {
    switch (_splitMode) {
      case SplitMode.equal:
        return Container(
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : Colors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            ),
            boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
          ),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  ),
                _EqualSplitMemberRow(
                  member: members[i],
                  isSelected: _selectedMemberIds.contains(members[i].id),
                  amountPaisa: _amountPaisa,
                  selectedCount: _selectedMemberIds.length,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final member = members[i];
                    setState(() {
                      if (_selectedMemberIds.contains(member.id)) {
                        if (_selectedMemberIds.length > 1) {
                          _selectedMemberIds.remove(member.id);
                        }
                      } else {
                        _selectedMemberIds.add(member.id);
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        );

      case SplitMode.custom:
        final allocatedPaisa = members.fold<int>(
          0,
          (sum, m) => sum + (Money.tryParsePaisa(_customControllers[m.id]?.text) ?? 0),
        );
        final remainingPaisa = _amountPaisa - allocatedPaisa;

        return Column(
          children: [
            // Allocation summary banner
            if (_amountPaisa > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: remainingPaisa == 0
                      ? CoSpendColors.jadeGreen.withValues(alpha: 0.1)
                      : (isDark ? CoSpendColors.darkCard : CoSpendColors.surfaceMuted),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Allocated: ${Money.format(allocatedPaisa)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    Text(
                      remainingPaisa == 0
                          ? 'Balanced ✓'
                          : 'Remaining: ${Money.format(remainingPaisa)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: remainingPaisa == 0
                            ? CoSpendColors.jadeGreen
                            : CoSpendColors.alertRed,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCard : Colors.white,
                borderRadius: CoSpendRadii.cardRadius,
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                ),
                boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
              ),
              child: Column(
                children: [
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark ? CoSpendColors.darkCanvas : const Color(0x140A2542),
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              member.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: TextFormField(
                              controller: _customControllers[member.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                prefixStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: isDark ? CoSpendColors.darkCanvas : const Color(0xFFF7F8FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark ? CoSpendColors.darkBorder : const Color(0x1A0A2542),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark ? CoSpendColors.darkBorder : const Color(0x1A0A2542),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      case SplitMode.percentage:
        final totalPct = members.fold<double>(
          0.0,
          (sum, m) => sum + (double.tryParse(_percentageControllers[m.id]?.text ?? '') ?? 0.0),
        );
        final isBalanced = (totalPct - 100.0).abs() < 0.1;

        return Column(
          children: [
            // Percentage summary banner
            if (_amountPaisa > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isBalanced
                      ? CoSpendColors.jadeGreen.withValues(alpha: 0.1)
                      : (isDark ? CoSpendColors.darkCard : CoSpendColors.surfaceMuted),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${totalPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBalanced
                            ? CoSpendColors.jadeGreen
                            : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                      ),
                    ),
                    Text(
                      isBalanced
                          ? '100% Balanced ✓'
                          : 'Must equal 100% (${(100.0 - totalPct).toStringAsFixed(1)}% left)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBalanced ? CoSpendColors.jadeGreen : CoSpendColors.alertRed,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCard : Colors.white,
                borderRadius: CoSpendRadii.cardRadius,
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                ),
                boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
              ),
              child: Column(
                children: [
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark ? CoSpendColors.darkCanvas : const Color(0x140A2542),
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                  ),
                                ),
                                Text(
                                  Money.format(
                                    (_amountPaisa *
                                            (double.tryParse(_percentageControllers[member.id]?.text ?? '0') ??
                                                0) /
                                            100)
                                        .round(),
                                  ),
                                  style: TextStyle(
                                    color: isDark ? CoSpendColors.darkTextMuted : const Color(0xFF6B7280),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 85,
                            child: TextFormField(
                              controller: _percentageControllers[member.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                              ),
                              decoration: InputDecoration(
                                suffixText: '%',
                                suffixStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: isDark ? CoSpendColors.darkCanvas : const Color(0xFFF7F8FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark ? CoSpendColors.darkBorder : const Color(0x1A0A2542),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark ? CoSpendColors.darkBorder : const Color(0x1A0A2542),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }

  // ===========================================================================
  // 8. PRIMARY CTA (Save / Add Expense)
  // ===========================================================================

  Widget _buildSaveButton(bool isFormValid, bool isSaving, List<HouseholdMember> members, bool isDark) {
    return Semantics(
      button: true,
      label: _isSuccess ? 'Expense added' : 'Save Expense',
      enabled: isFormValid && !isSaving,
      child: BouncingButton(
        scale: 0.98,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
          key: const ValueKey('save_expense_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSuccess ? CoSpendColors.jadeGreen : CoSpendColors.jadeGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark
                ? CoSpendColors.darkBorder
                : CoSpendColors.prussianBlue.withValues(alpha: 0.12),
            disabledForegroundColor: isDark
                ? CoSpendColors.darkTextMuted
                : CoSpendColors.prussianBlue.withValues(alpha: 0.35),
            elevation: isFormValid && !isSaving ? 2 : 0,
            shape: const StadiumBorder(),
            shadowColor: CoSpendColors.jadeGreen.withValues(alpha: 0.3),
          ),
          onPressed: isFormValid && !isSaving ? () => _submit(members) : null,
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : _isSuccess
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Added!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    ),
  );
}
}

// =============================================================================
// EQUAL SPLIT MEMBER ROW (With Animated Avatars & Selection Ring)
// =============================================================================

class _EqualSplitMemberRow extends StatelessWidget {
  const _EqualSplitMemberRow({
    required this.member,
    required this.isSelected,
    required this.amountPaisa,
    required this.selectedCount,
    required this.isDark,
    required this.onTap,
  });

  final HouseholdMember member;
  final bool isSelected;
  final int amountPaisa;
  final int selectedCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final perPersonAmount = (isSelected && selectedCount > 0) ? amountPaisa ~/ selectedCount : 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Animated Avatar with Selection Ring
            AnimatedContainer(
              duration: CoSpendAnimations.fast,
              curve: CoSpendAnimations.curveDefault,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? CoSpendColors.jadeGreen : Colors.transparent,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 0.95,
                duration: CoSpendAnimations.fast,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: isSelected
                      ? CoSpendColors.jadeGreen.withValues(alpha: 0.15)
                      : (isDark ? CoSpendColors.darkCanvas : const Color(0x140A2542)),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? CoSpendColors.jadeGreen
                          : (isDark ? Colors.white : CoSpendColors.prussianBlue),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Member Name + Status / Share
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? (perPersonAmount > 0 ? Money.format(perPersonAmount) : 'Included')
                        : 'Excluded',
                    style: TextStyle(
                      color: isSelected
                          ? CoSpendColors.jadeGreen
                          : (isDark ? CoSpendColors.darkTextMuted : const Color(0xFF9CA3AF)),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Checkbox Badge
            AnimatedContainer(
              duration: CoSpendAnimations.fast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? CoSpendColors.jadeGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? CoSpendColors.jadeGreen
                      : (isDark ? CoSpendColors.darkBorder : const Color(0xFFD1D5DB)),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CATEGORY TILE ITEM (For Modal Sheet)
// =============================================================================

class _CategoryTileItem extends StatelessWidget {
  const _CategoryTileItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? CoSpendColors.darkCard : CoSpendColors.surfaceMuted),
          border: Border.all(
            color: isSelected ? color : (isDark ? CoSpendColors.darkBorder : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SUBCATEGORY FILTER CHIP
// =============================================================================

class _SubcatChip extends StatelessWidget {
  const _SubcatChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: CoSpendAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? CoSpendColors.jadeGreen
              : (isDark ? CoSpendColors.darkCard : Colors.white),
          borderRadius: CoSpendRadii.pillRadius,
          border: Border.all(
            color: isSelected
                ? CoSpendColors.jadeGreen
                : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight),
          ),
          boxShadow: !isDark && !isSelected ? CoSpendShadows.cardSubtle : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : CoSpendColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
