import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Financial Insights Card - Ledgerify Design Language
///
/// Displays key financial metrics for a period:
/// - Total Income
/// - Total Expenses
/// - Net Income (savings)
/// - Savings Rate (percentage)
///
/// Follows the Quiet Finance philosophy: calm, professional, data-focused.
class FinancialInsightsCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final String periodLabel;

  const FinancialInsightsCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.periodLabel,
  });

  double get netIncome => totalIncome - totalExpenses;
  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;
  bool get isPositive => netIncome >= 0;

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              LedgerifySpacing.horizontalSm,
              Text(
                'Financial Summary',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.sm,
                  vertical: LedgerifySpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusSm,
                ),
                child: Text(
                  periodLabel,
                  style: LedgerifyTypography.labelSmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalLg,

          // Main metrics row
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Income',
                  value: totalIncome,
                  icon: Icons.arrow_downward_rounded,
                  valueColor: colors.accent,
                  colors: colors,
                ),
              ),
              LedgerifySpacing.horizontalMd,
              Expanded(
                child: _MetricTile(
                  label: 'Expenses',
                  value: totalExpenses,
                  icon: Icons.arrow_upward_rounded,
                  valueColor: colors.negative,
                  colors: colors,
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalLg,

          // Divider
          Container(
            height: 1,
            color: colors.surfaceHighlight,
          ),

          LedgerifySpacing.verticalLg,

          // Net income and savings rate row
          Row(
            children: [
              Expanded(
                child: _NetIncomeTile(
                  netIncome: netIncome,
                  isPositive: isPositive,
                  colors: colors,
                ),
              ),
              LedgerifySpacing.horizontalMd,
              Expanded(
                child: _SavingsRateTile(
                  savingsRate: savingsRate,
                  isPositive: isPositive,
                  colors: colors,
                ),
              ),
            ],
          ),

          // Insight message
          if (totalIncome > 0 || totalExpenses > 0) ...[
            LedgerifySpacing.verticalLg,
            _buildInsightMessage(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightMessage(LedgerifyColorScheme colors) {
    String message;
    IconData icon;
    Color iconColor;

    if (totalIncome == 0 && totalExpenses > 0) {
      message = 'No income recorded this period';
      icon = Icons.info_outline_rounded;
      iconColor = colors.textTertiary;
    } else if (savingsRate >= 30) {
      message = 'Excellent savings rate. Keep it up.';
      icon = Icons.check_circle_outline_rounded;
      iconColor = colors.accent;
    } else if (savingsRate >= 15) {
      message = 'Good progress on your savings.';
      icon = Icons.trending_up_rounded;
      iconColor = colors.accent;
    } else if (savingsRate >= 0) {
      message = 'Consider increasing your savings rate.';
      icon = Icons.lightbulb_outline_rounded;
      iconColor = colors.warning;
    } else {
      message = 'Expenses exceed income this period.';
      icon = Icons.warning_amber_rounded;
      iconColor = colors.negative;
    }

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
          LedgerifySpacing.horizontalSm,
          Expanded(
            child: Text(
              message,
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual metric tile for income/expenses
class _MetricTile extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color valueColor;
  final LedgerifyColorScheme colors;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: valueColor,
            ),
            LedgerifySpacing.horizontalXs,
            Text(
              label,
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        LedgerifySpacing.verticalXs,
        Text(
          CurrencyFormatter.format(value),
          style: LedgerifyTypography.amountMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Net income display tile
class _NetIncomeTile extends StatelessWidget {
  final double netIncome;
  final bool isPositive;
  final LedgerifyColorScheme colors;

  const _NetIncomeTile({
    required this.netIncome,
    required this.isPositive,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Income',
          style: LedgerifyTypography.labelSmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
        LedgerifySpacing.verticalXs,
        Row(
          children: [
            Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 18,
              color: isPositive ? colors.accent : colors.negative,
            ),
            LedgerifySpacing.horizontalXs,
            Expanded(
              child: Text(
                '${isPositive ? '+' : ''}${CurrencyFormatter.format(netIncome)}',
                style: LedgerifyTypography.amountMedium.copyWith(
                  color: isPositive ? colors.accent : colors.negative,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Savings rate display tile
class _SavingsRateTile extends StatelessWidget {
  final double savingsRate;
  final bool isPositive;
  final LedgerifyColorScheme colors;

  const _SavingsRateTile({
    required this.savingsRate,
    required this.isPositive,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Savings Rate',
          style: LedgerifyTypography.labelSmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
        LedgerifySpacing.verticalXs,
        Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 18,
              height: 18,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 3,
                    backgroundColor: colors.surfaceHighlight,
                    valueColor: AlwaysStoppedAnimation(colors.surfaceHighlight),
                  ),
                  CircularProgressIndicator(
                    value: (savingsRate.clamp(0, 100) / 100),
                    strokeWidth: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      isPositive ? colors.accent : colors.negative,
                    ),
                  ),
                ],
              ),
            ),
            LedgerifySpacing.horizontalSm,
            Text(
              '${savingsRate.toStringAsFixed(1)}%',
              style: LedgerifyTypography.amountMedium.copyWith(
                color: isPositive ? colors.accent : colors.negative,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
