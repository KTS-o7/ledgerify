import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Hero metric card that answers "Am I okay?" in 2 seconds.
///
/// Displays the primary financial health indicator with:
/// - Large net amount (saved or over budget)
/// - Secondary stats: income, expenses, month-over-month comparison
class HeroMetricCard extends StatelessWidget {
  /// Total income for the month
  final double totalIncome;

  /// Total expenses for the month
  final double totalExpenses;

  /// Previous month's expenses for comparison (optional)
  final double? previousMonthExpenses;

  /// Label for the current month (e.g., "October")
  final String monthLabel;

  /// Label for the comparison month (e.g., "Sep")
  final String? comparisonMonthLabel;

  const HeroMetricCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.monthLabel,
    this.previousMonthExpenses,
    this.comparisonMonthLabel,
  });

  /// Net amount (income - expenses)
  double get netAmount => totalIncome - totalExpenses;

  /// Percent change in expenses vs previous month
  /// Positive = spending more, Negative = spending less
  double? get percentChange {
    if (previousMonthExpenses == null || previousMonthExpenses == 0) {
      return null;
    }
    return ((totalExpenses - previousMonthExpenses!) / previousMonthExpenses!) *
        100;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero number section
          _buildHeroSection(colors),
          const SizedBox(height: LedgerifySpacing.xl),
          // Secondary stats row
          _buildSecondaryStatsRow(colors),
        ],
      ),
    );
  }

  Widget _buildHeroSection(LedgerifyColorScheme colors) {
    // Handle edge case: no income recorded
    if (totalIncome == 0 && totalExpenses == 0) {
      return Column(
        children: [
          Text(
            'No income recorded',
            style: LedgerifyTypography.headlineMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: LedgerifySpacing.xs),
          Text(
            'for $monthLabel',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      );
    }

    // Determine display properties based on net amount
    final isPositive = netAmount > 0;
    final isNeutral = netAmount == 0;
    final prefix = isPositive ? '+' : (netAmount < 0 ? '-' : '');
    final displayAmount = netAmount.abs();
    final amountColor = isNeutral
        ? colors.textSecondary
        : (isPositive ? colors.accent : colors.negative);
    final statusLabel = isPositive
        ? 'saved this month'
        : (isNeutral ? 'balanced this month' : 'over budget');

    return Column(
      children: [
        Text(
          '$prefix${CurrencyFormatter.format(displayAmount)}',
          style: LedgerifyTypography.amountHero.copyWith(
            color: amountColor,
          ),
        ),
        const SizedBox(height: LedgerifySpacing.xs),
        Text(
          statusLabel,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryStatsRow(LedgerifyColorScheme colors) {
    final hasComparison = percentChange != null && comparisonMonthLabel != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Income stat
        _buildSecondaryStat(
          colors: colors,
          amount: totalIncome,
          label: 'in',
          icon: Icons.arrow_downward_rounded,
        ),
        // Expenses stat
        _buildSecondaryStat(
          colors: colors,
          amount: totalExpenses,
          label: 'out',
          icon: Icons.arrow_upward_rounded,
        ),
        // Comparison stat (if available)
        if (hasComparison) _buildComparisonStat(colors),
      ],
    );
  }

  Widget _buildSecondaryStat({
    required LedgerifyColorScheme colors,
    required double amount,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colors.textTertiary,
        ),
        const SizedBox(width: LedgerifySpacing.xs),
        Text(
          CurrencyFormatter.format(amount),
          style: LedgerifyTypography.amountSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: LedgerifySpacing.xs),
        Text(
          label,
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonStat(LedgerifyColorScheme colors) {
    final change = percentChange!;
    // For expenses: increase is bad (negative indicator), decrease is good (positive indicator)
    // Arrow up = spending more = bad, Arrow down = spending less = good
    final isIncrease = change > 0;
    final isNeutral = change == 0;
    final icon =
        isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = isNeutral
        ? colors.textSecondary
        : (isIncrease ? colors.negative : colors.accent);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isNeutral)
          Icon(
            icon,
            size: 14,
            color: color,
          ),
        if (!isNeutral) const SizedBox(width: LedgerifySpacing.xs),
        Text(
          '${change.abs().toStringAsFixed(0)}%',
          style: LedgerifyTypography.amountSmall.copyWith(
            color: color,
          ),
        ),
        const SizedBox(width: LedgerifySpacing.xs),
        Text(
          'vs $comparisonMonthLabel',
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
