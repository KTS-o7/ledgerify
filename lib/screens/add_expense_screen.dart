import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Add/Edit Expense Screen - Ledgerify Design Language
///
/// A form screen for creating or editing an expense entry.
/// Features:
/// - Amount input with currency prefix
/// - Category dropdown with icons
/// - Date picker
/// - Optional note field
/// - Full-width primary action button
class AddExpenseScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final Expense? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    required this.expenseService,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _amountController = TextEditingController(
        text: expense.amount.toStringAsFixed(2),
      );
      _noteController = TextEditingController(text: expense.note ?? '');
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    } else {
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedCategory = ExpenseCategory.food;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select expense date',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool get _isFormValid {
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim();

      if (_isEditing) {
        final updated = widget.expenseToEdit!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isEmpty ? null : note,
        );
        await widget.expenseService.updateExpense(updated);
      } else {
        await widget.expenseService.addExpense(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isEmpty ? null : note,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving expense: $e',
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: colors.textPrimary,
        ),
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.accent,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(LedgerifySpacing.lg),
                    child: Form(
                      key: _formKey,
                      onChanged: () => setState(() {}),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAmountField(colors),
                          SizedBox(height: LedgerifySpacing.xl),
                          _buildCategoryDropdown(colors),
                          SizedBox(height: LedgerifySpacing.xl),
                          _buildDatePicker(colors),
                          SizedBox(height: LedgerifySpacing.xl),
                          _buildNoteField(colors),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom action button
                _buildBottomButton(colors),
              ],
            ),
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
        SizedBox(height: LedgerifySpacing.sm),
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
            prefixText: '₹ ',
            prefixStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textSecondary,
            ),
            hintText: '0.00',
            hintStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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

  Widget _buildCategoryDropdown(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: LedgerifySpacing.sm),
        DropdownButtonFormField<ExpenseCategory>(
          value: _selectedCategory,
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
            border: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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
          items: ExpenseCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 24,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: LedgerifySpacing.md),
                  Text(
                    category.displayName,
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
                _selectedCategory = value;
              });
            }
          },
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
        SizedBox(height: LedgerifySpacing.sm),
        InkWell(
          onTap: _selectDate,
          borderRadius: LedgerifyRadius.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.lg,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.format(_selectedDate),
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Note',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: LedgerifySpacing.sm),
            Text(
              '(optional)',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        SizedBox(height: LedgerifySpacing.sm),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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
            counterStyle: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
            contentPadding: const EdgeInsets.all(LedgerifySpacing.lg),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(LedgerifyColorScheme colors) {
    return Container(
      padding: EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        bottom: LedgerifySpacing.lg + MediaQuery.of(context).padding.bottom,
        top: LedgerifySpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(
            color: colors.surface,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isFormValid ? _saveExpense : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.background,
            disabledBackgroundColor: colors.surfaceHighlight,
            disabledForegroundColor: colors.textDisabled,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
          ),
          child: Text(
            _isEditing ? 'Update Expense' : 'Add Expense',
            style: LedgerifyTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: _isFormValid ? colors.background : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
