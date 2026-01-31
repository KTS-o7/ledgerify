import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Category Breakdown Card - Ledgerify Design Language
///
/// A collapsible card showing category-wise expense breakdown.
/// Default collapsed, expands with smooth animation.
/// Supports both light and dark themes.
class CategoryBreakdownCard extends StatefulWidget {
  final Map<ExpenseCategory, double> breakdown;
  final double total;

  const CategoryBreakdownCard({
    super.key,
    required this.breakdown,
    required this.total,
  });

  @override
  State<CategoryBreakdownCard> createState() => _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState extends State<CategoryBreakdownCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = LedgerifyColors.of(context);

    // Sort categories by amount (descending)
    final sortedEntries = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: LedgerifyRadius.borderRadiusLg,
            child: Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.pie_chart_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: LedgerifySpacing.md),
                  Text(
                    'Category Breakdown',
                    style: LedgerifyTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildBreakdownList(sortedEntries, colors),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(
    List<MapEntry<ExpenseCategory, double>> entries,
    LedgerifyColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        bottom: LedgerifySpacing.lg,
      ),
      child: Column(
        children: entries.map((entry) {
          final percentage =
              widget.total > 0 ? (entry.value / widget.total * 100) : 0.0;

          return _CategoryRow(
            category: entry.key,
            amount: entry.value,
            percentage: percentage,
            total: widget.total,
            colors: colors,
          );
        }).toList(),
      ),
    );
  }
}

/// A single row in the category breakdown with progress bar
class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percentage;
  final double total;
  final LedgerifyColorScheme colors;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LedgerifySpacing.md),
      child: Column(
        children: [
          // Main row: icon, name, amount
          Row(
            children: [
              // Category icon in container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(width: LedgerifySpacing.md),

              // Category name
              Expanded(
                child: Text(
                  category.displayName,
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Amount and percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(amount),
                    style: LedgerifyTypography.amountSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: LedgerifyTypography.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: LedgerifySpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total > 0 ? amount / total : 0,
              backgroundColor: colors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
