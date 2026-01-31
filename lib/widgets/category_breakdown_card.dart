import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Category Breakdown Card - Ledgerify Design Language
///
/// A collapsible card showing category-wise expense breakdown.
/// Default collapsed, expands with smooth animation.
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

    // Sort categories by amount (descending)
    final sortedEntries = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: LedgerifyColors.surface,
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
                    color: LedgerifyColors.textSecondary,
                  ),
                  SizedBox(width: LedgerifySpacing.md),
                  Text(
                    'Category Breakdown',
                    style: LedgerifyTypography.headlineSmall,
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: LedgerifyColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildBreakdownList(sortedEntries),
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

  Widget _buildBreakdownList(List<MapEntry<ExpenseCategory, double>> entries) {
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

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.total,
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
                  color: LedgerifyColors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: LedgerifyColors.textSecondary,
                ),
              ),
              SizedBox(width: LedgerifySpacing.md),

              // Category name
              Expanded(
                child: Text(
                  category.displayName,
                  style: LedgerifyTypography.bodyLarge,
                ),
              ),

              // Amount and percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(amount),
                    style: LedgerifyTypography.amountSmall,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: LedgerifyTypography.bodySmall.copyWith(
                      color: LedgerifyColors.textTertiary,
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
              backgroundColor: LedgerifyColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                LedgerifyColors.accent,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
