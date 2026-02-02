import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Cash Flow Summary Card - Ledgerify Design Language
///
/// Displays a monthly cash flow overview with income, expenses, and net balance.
/// Features a hero net amount with color-coded status (accent for positive,
/// negative for deficit), plus two side-by-side tiles for income and expenses.
///
/// Follows "Quiet Finance" design philosophy: calm, professional, no gamification.
class CashFlowSummaryCard extends StatelessWidget {
  /// The month being displayed
  final DateTime selectedMonth;

  /// Total income for the month
  final double totalIncome;

  /// Total expenses for the month
  final double totalExpenses;

  /// Number of income entries
  final int incomeCount;

  /// Number of expense entries
  final int expenseCount;

  /// Callback when previous month button is pressed
  final VoidCallback onPreviousMonth;

  /// Callback when next month button is pressed
  final VoidCallback onNextMonth;

  const CashFlowSummaryCard({
    super.key,
    required this.selectedMonth,
    required this.totalIncome,
    required this.totalExpenses,
    required this.incomeCount,
    required this.expenseCount,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  /// Net amount for the month (income - expenses)
  double get _netAmount => totalIncome - totalExpenses;

  /// Whether navigation to next month is allowed
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
          // Month title
          Text(
            DateFormatter.formatMonthYear(selectedMonth),
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textTertiary,
            ),
          ),

          LedgerifySpacing.verticalLg,

          // Net amount - hero display
          _buildNetAmount(colors),

          LedgerifySpacing.verticalXs,

          // "Net this month" label
          Text(
            'Net this month',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),

          LedgerifySpacing.verticalXl,

          // Income and Expense tiles
          _buildIncomeExpenseTiles(colors),

          LedgerifySpacing.verticalXl,

          // Month navigation row
          _buildMonthNavigation(colors),
        ],
      ),
    );
  }

  /// Builds the hero net amount display with appropriate color
  Widget _buildNetAmount(LedgerifyColorScheme colors) {
    final isPositive = _netAmount >= 0;
    final amountColor = isPositive ? colors.accent : colors.negative;
    final prefix = isPositive ? '+' : '';

    return Text(
      '$prefix${CurrencyFormatter.format(_netAmount.abs())}',
      style: LedgerifyTypography.amountHero.copyWith(
        color: amountColor,
      ),
    );
  }

  /// Builds the income and expense tiles side by side
  Widget _buildIncomeExpenseTiles(LedgerifyColorScheme colors) {
    return Row(
      children: [
        // Income tile
        Expanded(
          child: _buildTile(
            colors: colors,
            title: 'Income',
            amount: totalIncome,
            count: incomeCount,
            isIncome: true,
          ),
        ),
        LedgerifySpacing.horizontalMd,
        // Expense tile
        Expanded(
          child: _buildTile(
            colors: colors,
            title: 'Expenses',
            amount: totalExpenses,
            count: expenseCount,
            isIncome: false,
          ),
        ),
      ],
    );
  }

  /// Builds an individual tile for income or expenses
  Widget _buildTile({
    required LedgerifyColorScheme colors,
    required String title,
    required double amount,
    required int count,
    required bool isIncome,
  }) {
    // Income tile has subtle accent-tinted background
    // Expense tile uses surface highlight
    final backgroundColor =
        isIncome ? colors.accentMuted : colors.surfaceHighlight;
    final amountPrefix = isIncome ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: LedgerifyTypography.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          LedgerifySpacing.verticalSm,
          // Amount
          Text(
            '$amountPrefix${CurrencyFormatter.format(amount)}',
            style: LedgerifyTypography.amountMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          LedgerifySpacing.verticalXs,
          // Entry count
          Text(
            _getEntryCountText(count, isIncome ? 'entry' : 'entry'),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the month navigation row at the bottom
  Widget _buildMonthNavigation(LedgerifyColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: colors.textTertiary,
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
        LedgerifySpacing.horizontalSm,
        Text(
          DateFormatter.formatMonthYear(selectedMonth),
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.horizontalSm,
        IconButton(
          onPressed: _canGoNext ? onNextMonth : null,
          icon: const Icon(Icons.chevron_right_rounded),
          color: _canGoNext ? colors.textTertiary : colors.textDisabled,
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ],
    );
  }

  /// Returns pluralized entry count text
  String _getEntryCountText(int count, String singular) {
    if (count == 0) return 'No entries';
    if (count == 1) return '1 entry';
    return '$count entries';
  }
}
