import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Add/Edit Goal Sheet - Ledgerify Design Language
///
/// A bottom sheet for creating and editing savings goals.
/// Supports icon and color customization, optional deadline.
class AddEditGoalSheet extends StatefulWidget {
  final GoalService goalService;
  final Goal? existingGoal; // null = creating new

  const AddEditGoalSheet({
    super.key,
    required this.goalService,
    this.existingGoal,
  });

  /// Show as modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required GoalService goalService,
    Goal? existingGoal,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditGoalSheet(
        goalService: goalService,
        existingGoal: existingGoal,
      ),
    );
  }

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  late int _selectedIconCodePoint;
  late String _selectedColorHex;
  DateTime? _selectedDeadline;

  bool _isLoading = false;
  bool _isFormValid = false;

  bool get _isEditing => widget.existingGoal != null;

  /// Goal-related icon options
  static const List<IconData> _iconOptions = [
    Icons.beach_access_rounded, // Vacation
    Icons.flight_rounded, // Travel
    Icons.home_rounded, // Home
    Icons.directions_car_rounded, // Car
    Icons.phone_iphone_rounded, // Phone/Tech
    Icons.laptop_rounded, // Laptop
    Icons.school_rounded, // Education
    Icons.favorite_rounded, // Wedding/Love
    Icons.child_care_rounded, // Baby/Kids
    Icons.pets_rounded, // Pets
    Icons.sports_esports_rounded, // Gaming
    Icons.camera_alt_rounded, // Camera
    Icons.watch_rounded, // Watch
    Icons.diamond_rounded, // Jewelry
    Icons.celebration_rounded, // Party/Event
    Icons.fitness_center_rounded, // Fitness
    Icons.savings_rounded, // General savings
    Icons.emergency_rounded, // Emergency fund
    Icons.card_giftcard_rounded, // Gift
    Icons.more_horiz_rounded, // Other
  ];

  /// Color options (same as tags)
  static const List<String> _colorOptions = [
    '#66BB6A',
    '#EF5350',
    '#42A5F5',
    '#AB47BC',
    '#FFA726',
    '#26A69A',
    '#EC407A',
    '#7E57C2',
  ];

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final goal = widget.existingGoal!;
      _nameController = TextEditingController(text: goal.name);
      _amountController = TextEditingController(
        text: goal.targetAmount.toStringAsFixed(2),
      );
      _selectedIconCodePoint = goal.iconCodePoint;
      _selectedColorHex = goal.colorHex;
      _selectedDeadline = goal.deadline;
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _selectedIconCodePoint = Icons.savings_rounded.codePoint;
      _selectedColorHex = _colorOptions[0];
      _selectedDeadline = null;
    }

    _nameController.addListener(_checkFormValidity);
    _amountController.addListener(_checkFormValidity);
    _checkFormValidity();
  }

  void _checkFormValidity() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final deadlineValid =
        _selectedDeadline == null || _selectedDeadline!.isAfter(DateTime.now());

    final newValid =
        name.isNotEmpty && amount != null && amount > 0 && deadlineValid;

    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkFormValidity);
    _amountController.removeListener(_checkFormValidity);
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.trim());

      if (_isEditing) {
        final updatedGoal = widget.existingGoal!.copyWith(
          name: name,
          targetAmount: amount,
          iconCodePoint: _selectedIconCodePoint,
          colorHex: _selectedColorHex,
          deadline: _selectedDeadline,
        );
        await widget.goalService.updateGoal(updatedGoal);
      } else {
        await widget.goalService.createGoal(
          name: name,
          targetAmount: amount,
          iconCodePoint: _selectedIconCodePoint,
          colorHex: _selectedColorHex,
          deadline: _selectedDeadline,
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
              'Error saving goal: $e',
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

  Future<void> _deleteGoal() async {
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
          'Delete Goal',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this goal? This action cannot be undone.',
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
      await widget.goalService.deleteGoal(widget.existingGoal!.id);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting goal: $e',
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

  Future<void> _selectDeadline() async {
    final colors = LedgerifyColors.of(context);
    final now = DateTime.now();
    final initialDate = _selectedDeadline ?? now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now)
          ? initialDate
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.accent,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
      _checkFormValidity();
    }
  }

  void _clearDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
    _checkFormValidity();
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  _buildDragHandle(colors),
                  LedgerifySpacing.verticalMd,
                  // Header
                  _buildHeader(colors),
                  LedgerifySpacing.verticalXl,
                  // Name field
                  _buildNameField(colors),
                  LedgerifySpacing.verticalXl,
                  // Amount field
                  _buildAmountField(colors),
                  LedgerifySpacing.verticalXl,
                  // Icon picker
                  _buildIconPicker(colors),
                  LedgerifySpacing.verticalXl,
                  // Color picker
                  _buildColorPicker(colors),
                  LedgerifySpacing.verticalXl,
                  // Deadline picker
                  _buildDeadlinePicker(colors),
                  LedgerifySpacing.verticalXl,
                  // Action buttons
                  _buildActionButtons(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(LedgerifyColorScheme colors) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.textTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isEditing ? 'Edit Goal' : 'New Goal',
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

  Widget _buildNameField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Name',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _nameController,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Vacation Fund',
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
              vertical: LedgerifySpacing.md,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a goal name';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
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
          'Target Amount',
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
              return 'Please enter a target amount';
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
        ),
      ],
    );
  }

  Widget _buildIconPicker(LedgerifyColorScheme colors) {
    final selectedColor = _parseColor(_selectedColorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: LedgerifySpacing.sm,
            crossAxisSpacing: LedgerifySpacing.sm,
          ),
          itemCount: _iconOptions.length,
          itemBuilder: (context, index) {
            final icon = _iconOptions[index];
            final isSelected = icon.codePoint == _selectedIconCodePoint;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIconCodePoint = icon.codePoint;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.2)
                      : colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  border: isSelected
                      ? Border.all(color: selectedColor, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? selectedColor : colors.textSecondary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _colorOptions.map((colorHex) {
            final color = _parseColor(colorHex);
            final isSelected = colorHex == _selectedColorHex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColorHex = colorHex;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colors.textPrimary, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: colors.background,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline (Optional)',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GestureDetector(
          onTap: _selectDeadline,
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
                  size: 20,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Text(
                    _selectedDeadline != null
                        ? DateFormatter.format(_selectedDeadline!)
                        : 'No deadline set',
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: _selectedDeadline != null
                          ? colors.textPrimary
                          : colors.textTertiary,
                    ),
                  ),
                ),
                if (_selectedDeadline != null)
                  GestureDetector(
                    onTap: _clearDeadline,
                    child: Container(
                      padding: const EdgeInsets.all(LedgerifySpacing.xs),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_selectedDeadline != null &&
            !_selectedDeadline!.isAfter(DateTime.now()))
          Padding(
            padding: const EdgeInsets.only(top: LedgerifySpacing.xs),
            child: Text(
              'Deadline must be in the future',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.negative,
              ),
            ),
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
                onPressed: _deleteGoal,
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
              onPressed: _isFormValid ? _saveGoal : null,
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
