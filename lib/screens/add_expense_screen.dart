import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/tag_service.dart';
import '../services/custom_category_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/tag_chip_input.dart';
import '../widgets/category_picker_sheet.dart';
import 'add_recurring_screen.dart';

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
  final RecurringExpenseService? recurringService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final Expense? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    required this.expenseService,
    this.recurringService,
    required this.tagService,
    required this.customCategoryService,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isFormValid = false;

  // Tags and custom categories
  List<String> _selectedTagIds = [];
  String? _selectedCustomCategoryId;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _titleController = TextEditingController(text: expense.merchant ?? '');
      _amountController = TextEditingController(
        text: expense.amount.toStringAsFixed(2),
      );
      _noteController = TextEditingController(text: expense.note ?? '');
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
      _selectedTagIds = List<String>.from(expense.tagIds);
      _selectedCustomCategoryId = expense.customCategoryId;
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedCategory = ExpenseCategory.food;
      _selectedDate = DateTime.now();
      _selectedTagIds = [];
      _selectedCustomCategoryId = null;
    }

    // Listen to amount changes for form validity
    _amountController.addListener(_checkFormValidity);

    // Check initial validity (for edit mode)
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
    _titleController.dispose();
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim();

      if (_isEditing) {
        final updated = widget.expenseToEdit!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isEmpty ? null : note,
          merchant: title.isEmpty ? null : title,
          customCategoryId: _selectedCustomCategoryId,
          tagIds: _selectedTagIds,
          clearCustomCategory: _selectedCustomCategoryId == null,
        );
        await widget.expenseService.updateExpense(updated);
      } else {
        final expense = Expense(
          id: widget.expenseService.generateId(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isEmpty ? null : note,
          merchant: title.isEmpty ? null : title,
          customCategoryId: _selectedCustomCategoryId,
          tagIds: _selectedTagIds,
        );
        await widget.expenseService.updateExpense(expense);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitleField(colors),
                          LedgerifySpacing.verticalXl,
                          _buildAmountField(colors),
                          LedgerifySpacing.verticalXl,
                          _buildCategoryPicker(colors),
                          LedgerifySpacing.verticalXl,
                          _buildTagsSection(colors),
                          LedgerifySpacing.verticalXl,
                          _buildDatePicker(colors),
                          LedgerifySpacing.verticalXl,
                          _buildNoteField(colors),
                          // "Make this recurring" button (edit mode only)
                          if (_isEditing &&
                              widget.recurringService != null) ...[
                            LedgerifySpacing.verticalXxl,
                            _buildMakeRecurringButton(colors),
                          ],
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

  Widget _buildTitleField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Title',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.horizontalSm,
            Text(
              '(optional)',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Starbucks, Amazon, Uber',
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
              vertical: LedgerifySpacing.lg,
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

  Future<void> _openCategoryPicker() async {
    final result = await CategoryPickerSheet.show(
      context,
      customCategoryService: widget.customCategoryService,
      selectedBuiltIn:
          _selectedCustomCategoryId == null ? _selectedCategory : null,
      selectedCustomId: _selectedCustomCategoryId,
    );

    if (result != null) {
      setState(() {
        if (result.isBuiltIn) {
          _selectedCategory = result.builtInCategory!;
          _selectedCustomCategoryId = null;
        } else if (result.isCustom) {
          _selectedCustomCategoryId = result.customCategoryId;
          // Keep the built-in category for analytics grouping
          // The UI will display custom category info
        }
      });
    }
  }

  Widget _buildCategoryPicker(LedgerifyColorScheme colors) {
    // Determine what to display based on selection
    IconData displayIcon;
    String displayName;
    Color iconColor;

    if (_selectedCustomCategoryId != null) {
      final customCategory =
          widget.customCategoryService.getCategory(_selectedCustomCategoryId!);
      if (customCategory != null) {
        displayIcon = customCategory.icon;
        displayName = customCategory.name;
        iconColor = customCategory.color;
      } else {
        // Fallback if custom category was deleted
        displayIcon = _selectedCategory.icon;
        displayName = _selectedCategory.displayName;
        iconColor = colors.accent;
      }
    } else {
      displayIcon = _selectedCategory.icon;
      displayName = _selectedCategory.displayName;
      iconColor = colors.accent;
    }

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
        InkWell(
          onTap: _openCategoryPicker,
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
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    displayIcon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Text(
                    displayName,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(LedgerifyColorScheme colors) {
    return TagChipInput(
      tagService: widget.tagService,
      selectedTagIds: _selectedTagIds,
      onTagsChanged: (newTagIds) {
        setState(() {
          _selectedTagIds = newTagIds;
        });
      },
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
            LedgerifySpacing.horizontalSm,
            Text(
              '(optional)',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        LedgerifySpacing.verticalSm,
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
            counterStyle: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
            contentPadding: const EdgeInsets.all(LedgerifySpacing.lg),
          ),
        ),
      ],
    );
  }

  Widget _buildMakeRecurringButton(LedgerifyColorScheme colors) {
    return OutlinedButton.icon(
      onPressed: _navigateToMakeRecurring,
      icon: Icon(
        Icons.repeat_rounded,
        size: 20,
        color: colors.accent,
      ),
      label: Text(
        'Make this recurring',
        style: LedgerifyTypography.labelLarge.copyWith(
          color: colors.accent,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accent,
        side: BorderSide(
          color: colors.accent.withValues(alpha: 0.5),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
      ),
    );
  }

  void _navigateToMakeRecurring() {
    if (widget.recurringService == null) return;

    final expense = widget.expenseToEdit;
    if (expense == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringScreen(
          recurringService: widget.recurringService!,
          prefillFromExpense: expense,
        ),
      ),
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
            shape: const RoundedRectangleBorder(
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
