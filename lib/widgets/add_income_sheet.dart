import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income.dart';
import '../models/goal.dart';
import '../services/income_service.dart';
import '../services/goal_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Add Income Sheet - Ledgerify Design Language
///
/// A bottom sheet for adding or editing income entries with optional
/// goal allocation support. Allows users to distribute portions of
/// their income to different savings goals.
class AddIncomeSheet extends StatefulWidget {
  final IncomeService incomeService;
  final GoalService goalService;
  final Income? existingIncome; // null = creating new

  const AddIncomeSheet({
    super.key,
    required this.incomeService,
    required this.goalService,
    this.existingIncome,
  });

  /// Show as modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required IncomeService incomeService,
    required GoalService goalService,
    Income? existingIncome,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddIncomeSheet(
        incomeService: incomeService,
        goalService: goalService,
        existingIncome: existingIncome,
      ),
    );
  }

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  IncomeSource _selectedSource = IncomeSource.salary;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isFormValid = false;

  // Goal allocation state
  late List<Goal> _activeGoals;
  late Map<String, bool> _goalEnabled; // goalId -> enabled
  late Map<String, TextEditingController> _percentageControllers;

  bool get _isEditing => widget.existingIncome != null;

  @override
  void initState() {
    super.initState();

    // Initialize active goals
    _activeGoals = widget.goalService.getActiveGoals();
    _goalEnabled = {};
    _percentageControllers = {};

    if (_isEditing) {
      final income = widget.existingIncome!;
      _amountController = TextEditingController(
        text: income.amount.toStringAsFixed(2),
      );
      _descriptionController = TextEditingController(
        text: income.description ?? '',
      );
      _selectedSource = income.source;
      _selectedDate = income.date;

      // Initialize allocation state from existing income
      for (final goal in _activeGoals) {
        final existingAllocation = income.goalAllocations.firstWhere(
          (a) => a.goalId == goal.id,
          orElse: () =>
              GoalAllocation(goalId: goal.id, percentage: 0, amount: 0),
        );
        _goalEnabled[goal.id] = existingAllocation.percentage > 0;
        _percentageControllers[goal.id] = TextEditingController(
          text: existingAllocation.percentage > 0
              ? existingAllocation.percentage.toStringAsFixed(0)
              : '',
        );
      }
    } else {
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();

      // Initialize allocation state for new income
      for (final goal in _activeGoals) {
        _goalEnabled[goal.id] = false;
        _percentageControllers[goal.id] = TextEditingController();
      }
    }

    _amountController.addListener(_onFormChanged);
    for (final controller in _percentageControllers.values) {
      controller.addListener(_onFormChanged);
    }
    _checkFormValidity();
  }

  void _onFormChanged() {
    _checkFormValidity();
  }

  void _checkFormValidity() {
    final amount = double.tryParse(_amountController.text.trim());
    final amountValid = amount != null && amount > 0;
    final allocationValid = _getTotalAllocationPercentage() <= 100;
    final newValid = amountValid && allocationValid;

    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
      });
    }
  }

  double _getTotalAllocationPercentage() {
    double total = 0;
    for (final goal in _activeGoals) {
      if (_goalEnabled[goal.id] == true) {
        final percentage =
            double.tryParse(_percentageControllers[goal.id]?.text ?? '') ?? 0;
        total += percentage;
      }
    }
    return total;
  }

  double _getCalculatedAmount(double percentage) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    return (amount * percentage) / 100;
  }

  double _getTotalAllocatedAmount() {
    double total = 0;
    for (final goal in _activeGoals) {
      if (_goalEnabled[goal.id] == true) {
        final percentage =
            double.tryParse(_percentageControllers[goal.id]?.text ?? '') ?? 0;
        total += _getCalculatedAmount(percentage);
      }
    }
    return total;
  }

  double _getRemainingAmount() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    return amount - _getTotalAllocatedAmount();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFormChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    for (final controller in _percentageControllers.values) {
      controller.removeListener(_onFormChanged);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final colors = LedgerifyColors.of(context);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.accent,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate allocation percentage
    if (_getTotalAllocationPercentage() > 100) {
      final colors = LedgerifyColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total allocation cannot exceed 100%',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.negative,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      // Build goal allocations
      final allocations = <GoalAllocation>[];
      for (final goal in _activeGoals) {
        if (_goalEnabled[goal.id] == true) {
          final percentage =
              double.tryParse(_percentageControllers[goal.id]?.text ?? '') ?? 0;
          if (percentage > 0) {
            allocations.add(GoalAllocation(
              goalId: goal.id,
              percentage: percentage,
              amount: _getCalculatedAmount(percentage),
            ));
          }
        }
      }

      if (_isEditing) {
        // Update existing income
        final updatedIncome = widget.existingIncome!.copyWith(
          amount: amount,
          source: _selectedSource,
          description: description.isNotEmpty ? description : null,
          date: _selectedDate,
          goalAllocations: allocations,
        );
        await widget.incomeService.updateIncome(updatedIncome);
      } else {
        // Add new income
        await widget.incomeService.addIncome(
          amount: amount,
          source: _selectedSource,
          description: description.isNotEmpty ? description : null,
          date: _selectedDate,
          goalAllocations: allocations,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving income: $e',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteIncome() async {
    if (!_isEditing) return;

    final colors = LedgerifyColors.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Delete Income',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this income entry? Any goal allocations will be reversed.',
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.negative,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.incomeService.deleteIncome(widget.existingIncome!.id);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting income: $e',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _buildDragHandle(colors),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(LedgerifySpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(colors),
                      LedgerifySpacing.verticalXl,
                      // Amount field
                      _buildAmountField(colors),
                      LedgerifySpacing.verticalXl,
                      // Source dropdown
                      _buildSourceDropdown(colors),
                      LedgerifySpacing.verticalXl,
                      // Description field
                      _buildDescriptionField(colors),
                      LedgerifySpacing.verticalXl,
                      // Date picker
                      _buildDatePicker(colors),
                      // Goal allocations (only if there are active goals)
                      if (_activeGoals.isNotEmpty) ...[
                        LedgerifySpacing.verticalXl,
                        _buildGoalAllocationsSection(colors),
                      ],
                      LedgerifySpacing.verticalXl,
                      // Action buttons
                      _buildActionButtons(colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(LedgerifyColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.textTertiary,
            borderRadius: LedgerifyRadius.borderRadiusFull,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isEditing ? 'Edit Income' : 'Add Income',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(LedgerifySpacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: LedgerifyTypography.amountLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '\u20B9 ',
            prefixStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textSecondary,
            ),
            hintText: '0.00',
            hintStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: colors.accent,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: colors.negative,
                width: 1,
              ),
            ),
            errorStyle: LedgerifyTypography.bodySmall.copyWith(
              color: colors.negative,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.lg,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value.trim());
            if (amount == null) {
              return 'Please enter a valid number';
            }
            if (amount <= 0) {
              return 'Amount must be greater than 0';
            }
            return null;
          },
          autofocus: !_isEditing,
        ),
      ],
    );
  }

  Widget _buildSourceDropdown(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        DropdownButtonFormField<IncomeSource>(
          initialValue: _selectedSource,
          dropdownColor: colors.surfaceElevated,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textTertiary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: colors.accent,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
          ),
          items: IncomeSource.values.map((source) {
            return DropdownMenuItem<IncomeSource>(
              value: source,
              child: Row(
                children: [
                  Icon(
                    source.icon,
                    size: 24,
                    color: colors.textSecondary,
                  ),
                  LedgerifySpacing.horizontalMd,
                  Text(
                    source.displayName,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSource = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optional)',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _descriptionController,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: colors.accent,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 24,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Text(
                  DateFormatter.format(_selectedDate),
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalAllocationsSection(LedgerifyColorScheme colors) {
    final totalPercentage = _getTotalAllocationPercentage();
    final totalAllocated = _getTotalAllocatedAmount();
    final remaining = _getRemainingAmount();
    final isOverAllocated = totalPercentage > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allocate to Goals (optional)',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalMd,
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Column(
            children: [
              // Goal list
              ..._activeGoals.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;
                final isLast = index == _activeGoals.length - 1;
                return _buildGoalAllocationRow(colors, goal, isLast);
              }),
              // Summary
              Container(
                padding: const EdgeInsets.all(LedgerifySpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(LedgerifyRadius.lg),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total allocated',
                          style: LedgerifyTypography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${totalPercentage.toStringAsFixed(0)}% (${CurrencyFormatter.format(totalAllocated)})',
                          style: LedgerifyTypography.bodyMedium.copyWith(
                            color: isOverAllocated
                                ? colors.negative
                                : colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    LedgerifySpacing.verticalSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining',
                          style: LedgerifyTypography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(100 - totalPercentage).clamp(0, 100).toStringAsFixed(0)}% (${CurrencyFormatter.format(remaining.clamp(0, double.infinity))})',
                          style: LedgerifyTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (isOverAllocated) ...[
                      LedgerifySpacing.verticalSm,
                      Text(
                        'Total allocation cannot exceed 100%',
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.negative,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalAllocationRow(
    LedgerifyColorScheme colors,
    Goal goal,
    bool isLast,
  ) {
    final isEnabled = _goalEnabled[goal.id] ?? false;
    final percentage =
        double.tryParse(_percentageControllers[goal.id]?.text ?? '') ?? 0;
    final allocatedAmount = _getCalculatedAmount(percentage);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.md,
        vertical: LedgerifySpacing.sm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _goalEnabled[goal.id] = !isEnabled;
                if (!_goalEnabled[goal.id]!) {
                  _percentageControllers[goal.id]?.clear();
                }
              });
              _checkFormValidity();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isEnabled ? colors.accent : Colors.transparent,
                borderRadius: LedgerifyRadius.borderRadiusSm,
                border: Border.all(
                  color: isEnabled ? colors.accent : colors.textTertiary,
                  width: 2,
                ),
              ),
              child: isEnabled
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colors.background,
                    )
                  : null,
            ),
          ),
          LedgerifySpacing.horizontalMd,
          // Goal icon and name
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: goal.color.withValues(alpha: 0.15),
              borderRadius: LedgerifyRadius.borderRadiusSm,
            ),
            child: Icon(
              goal.icon,
              size: 18,
              color: goal.color,
            ),
          ),
          LedgerifySpacing.horizontalSm,
          Expanded(
            child: Text(
              goal.name,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: isEnabled ? colors.textPrimary : colors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Percentage input
          SizedBox(
            width: 56,
            child: TextFormField(
              controller: _percentageControllers[goal.id],
              enabled: isEnabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: isEnabled ? colors.textPrimary : colors.textTertiary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
                suffixText: '%',
                suffixStyle: LedgerifyTypography.bodyMedium.copyWith(
                  color: isEnabled ? colors.textSecondary : colors.textTertiary,
                ),
                filled: true,
                fillColor: isEnabled ? colors.surface : colors.surfaceHighlight,
                border: const OutlineInputBorder(
                  borderRadius: LedgerifyRadius.borderRadiusSm,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.sm,
                  vertical: LedgerifySpacing.xs,
                ),
                isDense: true,
              ),
            ),
          ),
          LedgerifySpacing.horizontalSm,
          // Calculated amount
          SizedBox(
            width: 80,
            child: Text(
              CurrencyFormatter.format(allocatedAmount),
              style: LedgerifyTypography.bodySmall.copyWith(
                color: isEnabled ? colors.accent : colors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LedgerifyColorScheme colors) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.lg),
          child: CircularProgressIndicator(
            color: colors.accent,
          ),
        ),
      );
    }

    return Row(
      children: [
        // Delete button (only if editing)
        if (_isEditing) ...[
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _deleteIncome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.negative,
                  side: BorderSide(
                    color: colors.negative.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'Delete',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: colors.negative,
                  ),
                ),
              ),
            ),
          ),
          LedgerifySpacing.horizontalMd,
        ],
        // Save button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isFormValid ? _saveIncome : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                disabledBackgroundColor: colors.surfaceHighlight,
                disabledForegroundColor: colors.textDisabled,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Save',
                style: LedgerifyTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isFormValid ? colors.background : colors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
