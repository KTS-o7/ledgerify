import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../models/recurring_expense.dart';
import '../services/recurring_expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../widgets/frequency_picker.dart';
import '../widgets/weekday_selector.dart';

/// Add/Edit Recurring Expense Screen - Ledgerify Design Language
///
/// A form screen for creating or editing a recurring expense template.
/// Features:
/// - Title input
/// - Amount input with currency prefix
/// - Category dropdown with icons
/// - Frequency picker with advanced options
/// - Start date picker
/// - Optional end date
/// - Note field
/// - Full-width primary action button
class AddRecurringScreen extends StatefulWidget {
  final RecurringExpenseService recurringService;
  final RecurringExpense? recurringToEdit;

  /// Pre-fill form from an existing expense (for "Make this recurring" feature)
  final Expense? prefillFromExpense;

  const AddRecurringScreen({
    super.key,
    required this.recurringService,
    this.recurringToEdit,
    this.prefillFromExpense,
  });

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _customIntervalController;

  late ExpenseCategory _selectedCategory;
  late RecurrenceFrequency _selectedFrequency;
  late DateTime _startDate;
  DateTime? _endDate;
  List<int> _selectedWeekdays = [];
  int? _dayOfMonth;
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  bool _isFormValid = false;

  bool get _isEditing => widget.recurringToEdit != null;
  bool get _isPrefilling => widget.prefillFromExpense != null;

  /// Determines if advanced options should be auto-expanded
  bool get _hasAdvancedOptionsSet {
    // End date is set
    if (_endDate != null) return true;
    // Note is set
    if (_noteController.text.trim().isNotEmpty) return true;
    // Non-monthly frequency with specific options
    if (_selectedFrequency == RecurrenceFrequency.weekly &&
        _selectedWeekdays.isNotEmpty) return true;
    if (_selectedFrequency == RecurrenceFrequency.monthly &&
        _dayOfMonth != null) return true;
    if (_selectedFrequency == RecurrenceFrequency.custom) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Editing an existing recurring expense
      final recurring = widget.recurringToEdit!;
      _titleController = TextEditingController(text: recurring.title);
      _amountController = TextEditingController(
        text: recurring.amount.toStringAsFixed(2),
      );
      _noteController = TextEditingController(text: recurring.note ?? '');
      _customIntervalController = TextEditingController(
        text: recurring.customIntervalDays.toString(),
      );
      _selectedCategory = recurring.category;
      _selectedFrequency = recurring.frequency;
      _startDate = recurring.startDate;
      _endDate = recurring.endDate;
      _selectedWeekdays = recurring.weekdays ?? [];
      _dayOfMonth = recurring.dayOfMonth;
    } else if (_isPrefilling) {
      // Pre-filling from an existing expense ("Make this recurring")
      final expense = widget.prefillFromExpense!;
      // Use merchant name as title, or category name as fallback
      final title = expense.merchant ?? expense.category.displayName;
      _titleController = TextEditingController(text: title);
      _amountController = TextEditingController(
        text: expense.amount.toStringAsFixed(2),
      );
      _noteController = TextEditingController(text: expense.note ?? '');
      _customIntervalController = TextEditingController(text: '7');
      _selectedCategory = expense.category;
      _selectedFrequency = RecurrenceFrequency.monthly; // Smart default
      _startDate = expense.date;
      _endDate = null;
      _selectedWeekdays = [];
      _dayOfMonth = expense.date.day; // Use expense date's day of month
    } else {
      // Creating a new recurring expense
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _customIntervalController = TextEditingController(text: '7');
      _selectedCategory = ExpenseCategory.bills;
      _selectedFrequency = RecurrenceFrequency.monthly;
      _startDate = DateTime.now();
      _endDate = null;
      _selectedWeekdays = [];
      _dayOfMonth = null;
    }

    // Listen to text changes for form validity
    _titleController.addListener(_checkFormValidity);
    _amountController.addListener(_checkFormValidity);
    _customIntervalController.addListener(_checkFormValidity);

    // Auto-expand advanced options when editing with advanced options set
    // Use post-frame callback to access controllers after they're initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFormValidity(); // Initial check
      if (_isEditing && _hasAdvancedOptionsSet) {
        setState(() {
          _showAdvancedOptions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkFormValidity);
    _amountController.removeListener(_checkFormValidity);
    _customIntervalController.removeListener(_checkFormValidity);
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    bool newValid = true;

    if (title.isEmpty || amount == null || amount <= 0) {
      newValid = false;
    }

    // For weekly with specific days, at least one day must be selected
    if (_selectedFrequency == RecurrenceFrequency.weekly &&
        _selectedWeekdays.isNotEmpty &&
        _selectedWeekdays.isEmpty) {
      newValid = false;
    }

    // For custom interval, must be at least 1
    if (_selectedFrequency == RecurrenceFrequency.custom) {
      final interval = int.tryParse(_customIntervalController.text.trim());
      if (interval == null || interval < 1) {
        newValid = false;
      }
    }

    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select start date',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Clear end date if it's before new start date
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
      helpText: 'Select end date (optional)',
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _clearEndDate() {
    setState(() {
      _endDate = null;
    });
  }

  Future<void> _saveRecurring() async {
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
      final customInterval =
          int.tryParse(_customIntervalController.text.trim()) ?? 1;

      if (_isEditing) {
        // Update existing recurring expense
        final updated = widget.recurringToEdit!.copyWith(
          title: title,
          amount: amount,
          category: _selectedCategory,
          frequency: _selectedFrequency,
          customIntervalDays: customInterval,
          weekdays: _selectedFrequency == RecurrenceFrequency.weekly
              ? (_selectedWeekdays.isNotEmpty ? _selectedWeekdays : null)
              : null,
          dayOfMonth: _selectedFrequency == RecurrenceFrequency.monthly
              ? _dayOfMonth
              : null,
          startDate: _startDate,
          endDate: _endDate,
          note: note.isEmpty ? null : note,
          clearWeekdays: _selectedFrequency != RecurrenceFrequency.weekly,
          clearDayOfMonth: _selectedFrequency != RecurrenceFrequency.monthly,
          clearEndDate: _endDate == null,
          clearNote: note.isEmpty,
        );
        await widget.recurringService.update(updated);
      } else {
        // Create new recurring expense
        await widget.recurringService.add(
          title: title,
          amount: amount,
          category: _selectedCategory,
          frequency: _selectedFrequency,
          customIntervalDays: customInterval,
          weekdays: _selectedFrequency == RecurrenceFrequency.weekly
              ? (_selectedWeekdays.isNotEmpty ? _selectedWeekdays : null)
              : null,
          dayOfMonth: _selectedFrequency == RecurrenceFrequency.monthly
              ? _dayOfMonth
              : null,
          startDate: _startDate,
          endDate: _endDate,
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
              'Error saving: $e',
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
          _isEditing ? 'Edit Recurring' : 'Add Recurring',
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
                          // Essential fields (always visible)
                          _buildTitleField(colors),
                          const SizedBox(height: LedgerifySpacing.xl),
                          _buildAmountField(colors),
                          const SizedBox(height: LedgerifySpacing.xl),
                          _buildCategoryDropdown(colors),
                          const SizedBox(height: LedgerifySpacing.xl),
                          FrequencyPicker(
                            value: _selectedFrequency,
                            onChanged: (frequency) {
                              setState(() {
                                _selectedFrequency = frequency;
                                // Auto-show advanced if frequency needs options
                                if (frequency == RecurrenceFrequency.weekly ||
                                    frequency == RecurrenceFrequency.custom) {
                                  _showAdvancedOptions = true;
                                }
                              });
                              _checkFormValidity();
                            },
                          ),
                          const SizedBox(height: LedgerifySpacing.xl),
                          _buildStartDatePicker(colors),

                          // Advanced options toggle
                          const SizedBox(height: LedgerifySpacing.xl),
                          _buildAdvancedOptionsToggle(colors),

                          // Advanced options (collapsible)
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: LedgerifySpacing.lg),
                                _buildFrequencyOptions(colors),
                                const SizedBox(height: LedgerifySpacing.xl),
                                _buildEndDatePicker(colors),
                                const SizedBox(height: LedgerifySpacing.xl),
                                _buildNoteField(colors),
                              ],
                            ),
                            crossFadeState: _showAdvancedOptions
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: LedgerifySpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomButton(colors),
              ],
            ),
    );
  }

  Widget _buildAdvancedOptionsToggle(LedgerifyColorScheme colors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showAdvancedOptions
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: colors.textTertiary,
          ),
          const SizedBox(width: LedgerifySpacing.xs),
          Text(
            _showAdvancedOptions
                ? 'Hide advanced options'
                : 'Show advanced options',
            style: LedgerifyTypography.labelMedium.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: LedgerifySpacing.sm),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Netflix, Rent, Gym',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.lg,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length > 100) {
              return 'Title must be 100 characters or less';
            }
            return null;
          },
          autofocus: !_isEditing,
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
              vertical: LedgerifySpacing.lg,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value.trim());
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
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

  Widget _buildFrequencyOptions(LedgerifyColorScheme colors) {
    switch (_selectedFrequency) {
      case RecurrenceFrequency.weekly:
        return WeekdaySelector(
          selectedDays: _selectedWeekdays,
          onChanged: (days) {
            setState(() {
              _selectedWeekdays = days;
            });
          },
        );

      case RecurrenceFrequency.monthly:
        return _buildDayOfMonthPicker(colors);

      case RecurrenceFrequency.custom:
        return _buildCustomIntervalField(colors);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDayOfMonthPicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day of month',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: LedgerifySpacing.sm),
        InkWell(
          onTap: () => _showDayOfMonthPicker(colors),
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
                  _dayOfMonth == null
                      ? 'Same as start date (${_startDate.day})'
                      : _dayOfMonth == 32
                          ? 'Last day of month'
                          : 'Day $_dayOfMonth',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
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

  void _showDayOfMonthPicker(LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: LedgerifySpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Text(
                'Select Day',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            // Same as start date option
            ListTile(
              leading: Icon(
                Icons.today_rounded,
                color:
                    _dayOfMonth == null ? colors.accent : colors.textSecondary,
              ),
              title: Text(
                'Same as start date (${_startDate.day})',
                style: TextStyle(
                  color:
                      _dayOfMonth == null ? colors.accent : colors.textPrimary,
                ),
              ),
              trailing: _dayOfMonth == null
                  ? Icon(Icons.check_rounded, color: colors.accent)
                  : null,
              onTap: () {
                setState(() {
                  _dayOfMonth = null;
                });
                Navigator.pop(context);
              },
            ),
            // Last day of month option
            ListTile(
              leading: Icon(
                Icons.last_page_rounded,
                color: _dayOfMonth == 32 ? colors.accent : colors.textSecondary,
              ),
              title: Text(
                'Last day of month',
                style: TextStyle(
                  color: _dayOfMonth == 32 ? colors.accent : colors.textPrimary,
                ),
              ),
              trailing: _dayOfMonth == 32
                  ? Icon(Icons.check_rounded, color: colors.accent)
                  : null,
              onTap: () {
                setState(() {
                  _dayOfMonth = 32;
                });
                Navigator.pop(context);
              },
            ),
            // Specific day options
            SizedBox(
              height: 200,
              child: GridView.builder(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: LedgerifySpacing.sm,
                  crossAxisSpacing: LedgerifySpacing.sm,
                ),
                itemCount: 31,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = _dayOfMonth == day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _dayOfMonth = day;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.accent
                            : colors.surfaceHighlight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: LedgerifyTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? colors.background
                                : colors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: LedgerifySpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIntervalField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat every',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: LedgerifySpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _customIntervalController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textAlign: TextAlign.center,
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceHighlight,
                  border: OutlineInputBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.md,
                    vertical: LedgerifySpacing.md,
                  ),
                ),
                validator: (value) {
                  if (_selectedFrequency != RecurrenceFrequency.custom) {
                    return null;
                  }
                  final interval = int.tryParse(value ?? '');
                  if (interval == null || interval < 1) {
                    return 'Min 1';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: LedgerifySpacing.md),
            Text(
              'days',
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartDatePicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start date',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: LedgerifySpacing.sm),
        InkWell(
          onTap: _selectStartDate,
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
                  _formatDate(_startDate),
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

  Widget _buildEndDatePicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'End date',
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
        InkWell(
          onTap: _selectEndDate,
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
                  _endDate != null ? _formatDate(_endDate!) : 'No end date',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: _endDate != null
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
                if (_endDate != null)
                  GestureDetector(
                    onTap: _clearEndDate,
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  )
                else
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
          maxLines: 2,
          maxLength: 200,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Add a note for generated expenses...',
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
          onPressed: _isFormValid ? _saveRecurring : null,
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
            _isEditing ? 'Update Recurring' : 'Add Recurring',
            style: LedgerifyTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: _isFormValid ? colors.background : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
