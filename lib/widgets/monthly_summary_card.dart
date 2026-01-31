import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Monthly Summary Card - Ledgerify Design Language
///
/// Displays the monthly total with navigation arrows.
/// Flat surface, no gradient, accent for emphasis.
/// Supports both light and dark themes.
class MonthlySummaryCard extends StatelessWidget {
  final DateTime selectedMonth;
  final double total;
  final int expenseCount;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthlySummaryCard({
    super.key,
    required this.selectedMonth,
    required this.total,
    required this.expenseCount,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  bool get _canGoNext {
    final now = DateTime.now();
    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Month navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: colors.textTertiary,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              Text(
                DateFormatter.formatMonthYear(selectedMonth),
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              IconButton(
                onPressed: _canGoNext ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: _canGoNext ? colors.textTertiary : colors.textDisabled,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalLg,

          // Total amount - hero display
          Text(
            CurrencyFormatter.format(total),
            style: LedgerifyTypography.amountHero.copyWith(
              color: colors.textPrimary,
            ),
          ),

          LedgerifySpacing.verticalSm,

          // Expense count
          Text(
            _getExpenseCountText(),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getExpenseCountText() {
    if (expenseCount == 0) return 'No expenses';
    if (expenseCount == 1) return '1 expense';
    return '$expenseCount expenses';
  }
}
