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

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _spentAt = picked);
    }
  }

  Future<void> _promptAddSubcategory(String categoryId) async {
    final controller = TextEditingController();
    final newSubcat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Chai, Groceries, Generator Fuel',
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  void _showPayerPicker(List<HouseholdMember> members) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Who paid?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final member in members)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(member.email),
                    trailing: _paidById == member.id
                        ? Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
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

    final householdId = ref.read(sessionProvider).value?.householdId;
    final currentUid = ref.read(sessionProvider).value?.user?.id;
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
          final pct =
              double.tryParse(_percentageControllers[m.id]?.text ?? '') ?? 0.0;
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

    await ref.read(expenseActionsProvider.notifier).addExpense(expense);

    final actionState = ref.read(expenseActionsProvider);
    if (!mounted) return;

    if (actionState.hasError) {
      final err = actionState.error!;
      final message = err is AppException
          ? err.message
          : FirebaseErrorMapper.messageFor(err);
      showAppSnack(context, message, error: true);
    } else {
      showAppSnack(context, 'Expense added successfully.');
      context.pop();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final membersAsync = ref.watch(householdMembersProvider);
    final isSaving = ref.watch(expenseActionsProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ADD EXPENSE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(FirebaseErrorMapper.messageFor(error)),
        ),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No household members found.'));
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // ── AMOUNT ──────────────────────────────────────────────────
                Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                    borderRadius: CoSpendRadii.cardRadius,
                    border: Border.all(
                      color: isDark
                          ? CoSpendColors.darkBorder
                          : CoSpendColors.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: isDark ? null : CoSpendShadows.card,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rs. ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : CoSpendColors.prussianBlue,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : const Color(0xFFCBD5E1),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: Validators.amount,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── WHAT WAS IT FOR? ─────────────────────────────────────────
                Text(
                  'WHAT WAS IT FOR?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Grocery shopping at Nature\'s Basket',
                    hintStyle: TextStyle(
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textSubtle,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? CoSpendColors.darkBorder
                            : const Color(0x1F0A2542),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? CoSpendColors.darkBorder
                            : const Color(0x1F0A2542),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: CoSpendColors.jadeGreen, width: 2),
                    ),
                  ),
                  validator: Validators.description,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // ── CATEGORY ─────────────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.label_outline_rounded,
                      size: 14,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final household =
                        ref.watch(currentHouseholdProvider).value;
                    final customCats =
                        household?.customCategories ?? const [];
                    final allCats = [
                      ...customCats.map((c) => _CategoryChipData(
                            id: c.id,
                            label: c.label,
                            icon: c.icon,
                            color: c.color,
                            isCustom: true,
                          )),
                      ...ExpenseCategory.values.map((c) => _CategoryChipData(
                            id: c.id,
                            label: c.label,
                            icon: c.icon,
                            color: c.color,
                            isCustom: false,
                          )),
                    ];

                    final activeCatId =
                        _selectedCustomCategory?.id ?? _category.id;

                    return SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allCats.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = allCats[index];
                          final isSelected = cat.id == activeCatId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (cat.isCustom) {
                                  _selectedCustomCategory = customCats
                                      .where((c) => c.id == cat.id)
                                      .firstOrNull;
                                  _category = ExpenseCategory.other;
                                } else {
                                  _category = ExpenseCategory.values
                                      .firstWhere((c) => c.id == cat.id);
                                  _selectedCustomCategory = null;
                                }
                                _selectedSubcategory = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CoSpendColors.jadeGreen
                                    : (isDark
                                        ? CoSpendColors.darkCard
                                        : CoSpendColors.white),
                                borderRadius: CoSpendRadii.pillRadius,
                                border: Border.all(
                                  color: isSelected
                                      ? CoSpendColors.jadeGreen
                                      : (isDark
                                          ? CoSpendColors.darkBorder
                                          : CoSpendColors.border),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : cat.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : CoSpendColors.textPrimary),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── SUBCATEGORY (OPTIONAL) ────────────────────────────────────
                Builder(
                  builder: (context) {
                    final activeCatId =
                        _selectedCustomCategory?.id ?? _category.id;
                    final household =
                        ref.watch(currentHouseholdProvider).value;
                    final availableSubcats =
                        household?.getSubcategories(activeCatId) ??
                            defaultCategorySubcategories[activeCatId] ??
                            const [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionLabel('SUBCATEGORY (OPTIONAL)'),
                            if (_selectedSubcategory != null)
                              GestureDetector(
                                onTap: () => setState(
                                    () => _selectedSubcategory = null),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CoSpendColors.alertRed,
                                    fontWeight: FontWeight.w600,
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
                              ...availableSubcats.map((subcat) {
                                final isSelected =
                                    _selectedSubcategory == subcat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(subcat),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    avatar: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                    backgroundColor: Colors.white,
                                    selectedColor: CoSpendColors.jadeGreen,
                                    shape: const StadiumBorder(),
                                    side: BorderSide(
                                      color: isSelected
                                          ? CoSpendColors.jadeGreen
                                          : const Color(0x1F0A2542),
                                    ),
                                    labelStyle: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                      fontSize: 12,
                                    ),
                                    onSelected: (selected) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedSubcategory =
                                            selected ? subcat : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                              ActionChip(
                                avatar: const Icon(Icons.add_rounded,
                                    size: 16,
                                    color: CoSpendColors.prussianBlue),
                                label: const Text('Add Subcategory'),
                                backgroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                side: const BorderSide(
                                    color: Color(0x1F0A2542)),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: CoSpendColors.prussianBlue,
                                  fontSize: 12,
                                ),
                                onPressed: () =>
                                    _promptAddSubcategory(activeCatId),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // ── PAID BY ───────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? CoSpendColors.darkBorder : const Color(0x1F0A2542),
                      width: 0.8,
                    ),
                    boxShadow: isDark ? null : CoSpendShadows.card,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: CoSpendColors.prussianBlue,
                        child: Text(
                          payer.name.isNotEmpty
                              ? payer.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              payer.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : CoSpendColors.prussianBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "You" badge — indicates this is always the current user
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: CoSpendColors.jadeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── SPLIT WITH ────────────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 16,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SPLIT WITH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CoSpendColors.jadeGreen
                            .withValues(alpha: 0.12),
                        borderRadius: CoSpendRadii.pillRadius,
                        border: Border.all(
                          color: CoSpendColors.jadeGreen
                              .withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'Household Group',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Segmented control: Equal | Custom | % Split
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CoSpendColors.darkCard
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (final mode in SplitMode.values)
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _splitMode = mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _splitMode == mode
                                    ? (isDark
                                        ? CoSpendColors.darkCanvas
                                        : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _splitMode == mode && !isDark
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                mode == SplitMode.equal
                                    ? 'Equal'
                                    : mode == SplitMode.custom
                                        ? 'Custom'
                                        : '% Split',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _splitMode == mode
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _splitMode == mode
                                      ? (isDark
                                          ? Colors.white
                                          : CoSpendColors.prussianBlue)
                                      : (isDark
                                          ? CoSpendColors.darkTextMuted
                                          : CoSpendColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Split Validation Warning
                if (splitValidationError != null && _amountPaisa > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CoSpendColors.alertRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoSpendColors.alertRed
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: CoSpendColors.alertRed, size: 20),
                        const SizedBox(width: 10),
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

                // Participant list per split mode
                _buildSplitSection(theme, scheme, members),

                const SizedBox(height: 16),

                // ── DATE & TAX ROW ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? CoSpendColors.darkCard
                                : CoSpendColors.white,
                            borderRadius: CoSpendRadii.cardRadius,
                            border: Border.all(
                              color: isDark
                                  ? CoSpendColors.darkBorder
                                  : CoSpendColors.borderLight,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isToday(_spentAt)
                                    ? 'Today, ${DateFormat('MMM dd').format(_spentAt)}'
                                    : DateFormat('MMM dd, yyyy')
                                        .format(_spentAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CoSpendColors.darkCard
                            : CoSpendColors.white,
                        borderRadius: CoSpendRadii.cardRadius,
                        border: Border.all(
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : CoSpendColors.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 15,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tax Included',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : CoSpendColors.prussianBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── SAVE EXPENSE BUTTON ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoSpendColors.jadeGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? CoSpendColors.darkCard
                          : CoSpendColors.prussianBlue
                              .withValues(alpha: 0.08),
                      disabledForegroundColor:
                          CoSpendColors.prussianBlue.withValues(alpha: 0.35),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: isFormValid && !isSaving
                        ? () => _submit(members)
                        : null,
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Save Expense',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitSection(
    ThemeData theme,
    ColorScheme scheme,
    List<HouseholdMember> members,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    switch (_splitMode) {
      case SplitMode.equal:
        return Container(
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color: isDark
                  ? CoSpendColors.darkBorder
                  : CoSpendColors.borderLight,
              width: 0.8,
            ),
            boxShadow: isDark ? null : CoSpendShadows.card,
          ),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: isDark
                        ? CoSpendColors.darkBorder
                        : const Color(0x0F0A2542),
                  ),
                InkWell(
                  onTap: () {
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
                  borderRadius: CoSpendRadii.cardRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isDark
                              ? CoSpendColors.darkCanvas
                              : const Color(0xFFEEF2F7),
                          child: Text(
                            members[i].name.isNotEmpty
                                ? members[i].name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : CoSpendColors.prussianBlue,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                members[i].name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Household Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? CoSpendColors.darkTextMuted
                                      : CoSpendColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Share amount + label
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _selectedMemberIds.contains(members[i].id) &&
                                      _selectedMemberIds.isNotEmpty
                                  ? 'Rs. ${(_amountPaisa / _selectedMemberIds.length / 100).toStringAsFixed(2)}'
                                  : 'Excluded',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _selectedMemberIds
                                        .contains(members[i].id)
                                    ? (isDark
                                        ? Colors.white
                                        : CoSpendColors.prussianBlue)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedMemberIds.contains(members[i].id)
                                  ? 'EQUAL SHARE'
                                  : 'EXCLUDED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color:
                                    _selectedMemberIds.contains(members[i].id)
                                        ? CoSpendColors.textMuted
                                        : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case SplitMode.custom:
        return Container(
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color: isDark
                  ? CoSpendColors.darkBorder
                  : CoSpendColors.borderLight,
              width: 0.8,
            ),
            boxShadow: isDark ? null : CoSpendShadows.card,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              for (final member in members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark
                            ? CoSpendColors.darkCanvas
                            : const Color(0x140A2542),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
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
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          controller: _customControllers[member.id],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            prefixText: 'Rs. ',
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? CoSpendColors.darkCanvas
                                : const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? CoSpendColors.darkBorder
                                    : const Color(0x1A0A2542),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? CoSpendColors.darkBorder
                                    : const Color(0x1A0A2542),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

      case SplitMode.percentage:
        return Container(
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: CoSpendRadii.cardRadius,
            border: Border.all(
              color: isDark
                  ? CoSpendColors.darkBorder
                  : CoSpendColors.borderLight,
              width: 0.8,
            ),
            boxShadow: isDark ? null : CoSpendShadows.card,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              for (final member in members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark
                            ? CoSpendColors.darkCanvas
                            : const Color(0x140A2542),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
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
                                color: isDark
                                    ? Colors.white
                                    : CoSpendColors.prussianBlue,
                              ),
                            ),
                            Text(
                              Money.format(
                                (_amountPaisa *
                                        (double.tryParse(
                                                  _percentageControllers[
                                                          member.id]
                                                      ?.text ??
                                                  '0',
                                                ) ??
                                                0) /
                                        100)
                                    .round(),
                              ),
                              style: TextStyle(
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _percentageControllers[member.id],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,1}')),
                          ],
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            suffixText: '%',
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? CoSpendColors.darkCanvas
                                : const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? CoSpendColors.darkBorder
                                    : const Color(0x1A0A2542),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? CoSpendColors.darkBorder
                                    : const Color(0x1A0A2542),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Chip Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipData {
  const _CategoryChipData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.isCustom,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isCustom;
}
