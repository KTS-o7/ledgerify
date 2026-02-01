import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Contribution Sheet - Ledgerify Design Language
///
/// A bottom sheet for adding or withdrawing money from a savings goal.
/// Supports quick amount selection and validation.
class ContributionSheet extends StatefulWidget {
  final Goal goal;
  final GoalService goalService;
  final bool isWithdraw;

  const ContributionSheet({
    super.key,
    required this.goal,
    required this.goalService,
    this.isWithdraw = false,
  });

  /// Show as modal bottom sheet
  /// Returns `true` if contribution was made, `false` if cancelled.
  static Future<bool> show(
    BuildContext context, {
    required Goal goal,
    required GoalService goalService,
    bool isWithdraw = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContributionSheet(
        goal: goal,
        goalService: goalService,
        isWithdraw: isWithdraw,
      ),
    );
    return result ?? false;
  }

  @override
  State<ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<ContributionSheet> {
  late TextEditingController _amountController;
  final FocusNode _amountFocusNode = FocusNode();

  bool _isLoading = false;
  double _enteredAmount = 0;

  /// Quick amount options
  static const List<double> _quickAmounts = [500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountController.addListener(_onAmountChanged);

    // Auto-focus the amount field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    setState(() {
      _enteredAmount = amount;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get _isValidAmount {
    if (_enteredAmount <= 0) return false;
    if (widget.isWithdraw && _enteredAmount > widget.goal.currentAmount) {
      return false;
    }
    return true;
  }

  Future<void> _submitContribution() async {
    if (!_isValidAmount) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wasCompleted = widget.goal.isCompleted;

      if (widget.isWithdraw) {
        await widget.goalService.withdrawContribution(
          widget.goal.id,
          _enteredAmount,
        );
      } else {
        await widget.goalService.addContribution(
          widget.goal.id,
          _enteredAmount,
        );
      }

      if (mounted) {
        final colors = LedgerifyColors.of(context);

        // Check if goal was just completed
        final updatedGoal = widget.goalService.getGoal(widget.goal.id);
        final justCompleted =
            !wasCompleted && (updatedGoal?.isCompleted ?? false);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              justCompleted
                  ? 'Goal completed! ${CurrencyFormatter.format(_enteredAmount)} added.'
                  : widget.isWithdraw
                      ? '${CurrencyFormatter.format(_enteredAmount)} withdrawn'
                      : '${CurrencyFormatter.format(_enteredAmount)} added',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: justCompleted ? colors.accent : colors.surface,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.negative,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
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

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
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
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              _buildDragHandle(colors),
              LedgerifySpacing.verticalMd,
              // Title
              _buildTitle(colors),
              LedgerifySpacing.verticalLg,
              // Progress context
              _buildProgressContext(colors),
              LedgerifySpacing.verticalXl,
              // Amount input
              _buildAmountInput(colors),
              LedgerifySpacing.verticalLg,
              // Quick amounts
              _buildQuickAmounts(colors),
              LedgerifySpacing.verticalLg,
              // Helper text
              _buildHelperText(colors),
              LedgerifySpacing.verticalXl,
              // Action button
              _buildActionButton(colors),
            ],
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

  Widget _buildTitle(LedgerifyColorScheme colors) {
    final action = widget.isWithdraw ? 'Withdraw from' : 'Add to';
    return Text(
      '$action ${widget.goal.name}',
      style: LedgerifyTypography.headlineMedium.copyWith(
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildProgressContext(LedgerifyColorScheme colors) {
    final progress = widget.goal.progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current / Target text
        Text(
          'Current: ${CurrencyFormatter.format(widget.goal.currentAmount)} of ${CurrencyFormatter.format(widget.goal.targetAmount)}',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: widget.goal.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput(LedgerifyColorScheme colors) {
    return TextFormField(
      controller: _amountController,
      focusNode: _amountFocusNode,
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
        hintText: '0',
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.lg,
        ),
      ),
    );
  }

  Widget _buildQuickAmounts(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick amounts:',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Row(
          children: _quickAmounts.map((amount) {
            final isSelected = _enteredAmount == amount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: amount == _quickAmounts.last ? 0 : LedgerifySpacing.sm,
                ),
                child: GestureDetector(
                  onTap: () => _selectQuickAmount(amount),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: LedgerifySpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accent.withValues(alpha: 0.15)
                          : colors.surfaceHighlight,
                      borderRadius: LedgerifyRadius.borderRadiusSm,
                      border: isSelected
                          ? Border.all(color: colors.accent, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        CurrencyFormatter.format(amount).replaceAll('.00', ''),
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color:
                              isSelected ? colors.accent : colors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHelperText(LedgerifyColorScheme colors) {
    String text;
    Color textColor = colors.textTertiary;

    if (widget.isWithdraw) {
      // Withdraw mode
      if (_enteredAmount > widget.goal.currentAmount) {
        text =
            'Cannot withdraw more than ${CurrencyFormatter.format(widget.goal.currentAmount)}';
        textColor = colors.negative;
      } else {
        text =
            'Available to withdraw: ${CurrencyFormatter.format(widget.goal.currentAmount)}';
      }
    } else {
      // Add mode
      final remaining = widget.goal.remainingAmount;
      if (remaining > 0) {
        text = 'Remaining to goal: ${CurrencyFormatter.format(remaining)}';
      } else {
        text = 'Goal already reached';
        textColor = colors.accent;
      }
    }

    return Text(
      text,
      style: LedgerifyTypography.bodySmall.copyWith(
        color: textColor,
      ),
    );
  }

  Widget _buildActionButton(LedgerifyColorScheme colors) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
          child: CircularProgressIndicator(
            color: colors.accent,
          ),
        ),
      );
    }

    final buttonText = _enteredAmount > 0
        ? '${widget.isWithdraw ? 'Withdraw' : 'Add'} ${CurrencyFormatter.format(_enteredAmount)}'
        : widget.isWithdraw
            ? 'Withdraw'
            : 'Add';

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isValidAmount ? _submitContribution : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isWithdraw ? colors.warning : colors.accent,
          foregroundColor: colors.background,
          disabledBackgroundColor: colors.surfaceHighlight,
          disabledForegroundColor: colors.textDisabled,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
        ),
        child: Text(
          buttonText,
          style: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: _isValidAmount ? colors.background : colors.textDisabled,
          ),
        ),
      ),
    );
  }
}
