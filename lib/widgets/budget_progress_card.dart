import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Budget Progress Card - Ledgerify Design Language
///
/// Displays budget overview with progress bars.
/// Shows overall budget and category-specific budgets.
/// Progress bar colors indicate budget status (ok/warning/exceeded).
class BudgetProgressCard extends StatelessWidget {
  final List<BudgetProgress> budgetProgressList;
  final VoidCallback onAddBudget;
  final Function(Budget budget) onEditBudget;

  const BudgetProgressCard({
    super.key,
    required this.budgetProgressList,
    required this.onAddBudget,
    required this.onEditBudget,
  });

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
          // Header with add button
          _buildHeader(colors),
          LedgerifySpacing.verticalLg,
          // Budget list or empty state
          if (budgetProgressList.isEmpty)
            _buildEmptyState(colors)
          else
            _buildBudgetList(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Budget Overview',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onAddBudget,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.sm,
              vertical: LedgerifySpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.accentMuted,
              borderRadius: LedgerifyRadius.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: colors.accent,
                ),
                LedgerifySpacing.horizontalXs,
                Text(
                  'Add',
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'No budgets set',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalMd,
            GestureDetector(
              onTap: onAddBudget,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                  vertical: LedgerifySpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Text(
                  'Add Budget',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: colors.brightness == Brightness.dark
                        ? const Color(0xFF121212)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(LedgerifyColorScheme colors) {
    return Column(
      children: budgetProgressList.asMap().entries.map((entry) {
        final index = entry.key;
        final progress = entry.value;
        return Column(
          children: [
            if (index > 0) LedgerifySpacing.verticalLg,
            _buildBudgetRow(progress, colors),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBudgetRow(BudgetProgress progress, LedgerifyColorScheme colors) {
    final budget = progress.budget;
    final label =
        budget.isOverallBudget ? 'Overall' : budget.category!.displayName;
    final percentText = '${(progress.percentage * 100).toStringAsFixed(0)}%';
    final progressColor = _getProgressColor(progress.status, colors);

    return GestureDetector(
      onTap: () => onEditBudget(budget),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          LedgerifySpacing.verticalXs,
          // Amount row
          Text(
            '${CurrencyFormatter.format(progress.spent)} / ${CurrencyFormatter.format(budget.amount)}',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          LedgerifySpacing.verticalSm,
          // Progress bar with percentage
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                    progress.percentage, progressColor, colors),
              ),
              LedgerifySpacing.horizontalSm,
              SizedBox(
                width: 44,
                child: Text(
                  percentText,
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: progressColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double percentage,
    Color progressColor,
    LedgerifyColorScheme colors,
  ) {
    // Clamp visual progress to 1.0 (100%) max
    final clampedProgress = percentage.clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusFull,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * clampedProgress,
                height: 8,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: LedgerifyRadius.borderRadiusFull,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProgressColor(BudgetStatus status, LedgerifyColorScheme colors) {
    switch (status) {
      case BudgetStatus.ok:
        return colors.accent;
      case BudgetStatus.warning:
        return const Color(0xFFFFA726); // Amber
      case BudgetStatus.exceeded:
        return colors.negative;
    }
  }
}
