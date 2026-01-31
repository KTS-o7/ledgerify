import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Monthly Summary Card - Ledgerify Design Language
///
/// Displays the monthly total with navigation arrows.
/// Flat surface, no gradient, pistachio accent for emphasis.
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

  /// Check if navigation to next month is allowed (can't go to future)
  bool get _canGoNext {
    final now = DateTime.now();
    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.xl),
      decoration: BoxDecoration(
        color: LedgerifyColors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Month navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous month button
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: LedgerifyColors.textTertiary,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              // Month/Year display
              Text(
                DateFormatter.formatMonthYear(selectedMonth),
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: LedgerifyColors.textTertiary,
                ),
              ),
              // Next month button
              IconButton(
                onPressed: _canGoNext ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: _canGoNext
                    ? LedgerifyColors.textTertiary
                    : LedgerifyColors.textDisabled,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),

          SizedBox(height: LedgerifySpacing.lg),

          // Total amount - hero display
          Text(
            CurrencyFormatter.format(total),
            style: LedgerifyTypography.amountHero,
          ),

          SizedBox(height: LedgerifySpacing.sm),

          // Expense count
          Text(
            _getExpenseCountText(),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: LedgerifyColors.textTertiary,
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
