import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/budget_service.dart';
import '../theme/ledgerify_theme.dart';

/// Budget Setup Sheet - Ledgerify Design Language
///
/// A bottom sheet for adding or editing budgets.
/// Allows setting overall budget or category-specific budgets.
class BudgetSetupSheet extends StatefulWidget {
  final BudgetService budgetService;
  final Budget? existingBudget; // null = creating new
  final int year;
  final int month;

  const BudgetSetupSheet({
    super.key,
    required this.budgetService,
    this.existingBudget,
    required this.year,
    required this.month,
  });

  /// Show as modal bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required BudgetService budgetService,
    Budget? existingBudget,
    required int year,
    required int month,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetSetupSheet(
        budgetService: budgetService,
        existingBudget: existingBudget,
        year: year,
        month: month,
      ),
    );
  }

  @override
  State<BudgetSetupSheet> createState() => _BudgetSetupSheetState();
}

class _BudgetSetupSheetState extends State<BudgetSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  // null = Overall Budget, otherwise a specific category
  ExpenseCategory? _selectedCategory;
  bool _isLoading = false;
  bool _isFormValid = false;

  bool get _isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final budget = widget.existingBudget!;
      _amountController = TextEditingController(
        text: budget.amount.toStringAsFixed(2),
      );
      _selectedCategory = budget.category;
    } else {
      _amountController = TextEditingController();
      _selectedCategory = null; // Default to overall budget
    }

    _amountController.addListener(_checkFormValidity);
    _checkFormValidity();
  }

  void _checkFormValidity() {
    final amount = double.tryParse(_amountController.text.trim());
    final newValid = amount != null && amount > 0;
    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_checkFormValidity);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());

      await widget.budgetService.setBudget(
        category: _selectedCategory,
        amount: amount,
        year: widget.year,
        month: widget.month,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving budget: $e',
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

  Future<void> _deleteBudget() async {
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
          'Delete Budget',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this budget?',
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
      await widget.budgetService.deleteBudget(widget.existingBudget!.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting budget: $e',
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
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(colors),
                LedgerifySpacing.verticalXl,
                // Category dropdown
                _buildCategoryDropdown(colors),
                LedgerifySpacing.verticalXl,
                // Amount field
                _buildAmountField(colors),
                LedgerifySpacing.verticalXl,
                // Action buttons
                _buildActionButtons(colors),
              ],
            ),
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
          _isEditing ? 'Edit Budget' : 'Set Budget',
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

  Widget _buildCategoryDropdown(LedgerifyColorScheme colors) {
    // Build dropdown items: Overall Budget first, then all categories
    final List<DropdownMenuItem<ExpenseCategory?>> items = [
      DropdownMenuItem<ExpenseCategory?>(
        value: null,
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 24,
              color: colors.textSecondary,
            ),
            LedgerifySpacing.horizontalMd,
            Text(
              'Overall Budget',
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      ...ExpenseCategory.values.map((category) {
        return DropdownMenuItem<ExpenseCategory?>(
          value: category,
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 24,
                color: colors.textSecondary,
              ),
              LedgerifySpacing.horizontalMd,
              Text(
                category.displayName,
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        IgnorePointer(
          ignoring: _isEditing, // Disable if editing
          child: Opacity(
            opacity: _isEditing ? 0.6 : 1.0,
            child: DropdownButtonFormField<ExpenseCategory?>(
              initialValue: _selectedCategory,
              dropdownColor: colors.surfaceElevated,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _isEditing ? colors.textDisabled : colors.textTertiary,
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
              items: items,
              onChanged: _isEditing
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
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
          'Monthly Limit',
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
            prefixText: '\u20B9 ', // Rupee symbol
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
                onPressed: _deleteBudget,
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
              onPressed: _isFormValid ? _saveBudget : null,
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
