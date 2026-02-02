import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Data class representing a single category breakdown item.
///
/// Used by [CategoryBreakdownList] to display spending by category
/// with optional comparison to a previous period.
class CategoryBreakdownItem {
  /// The expense category (null if using custom category).
  final ExpenseCategory? category;

  /// Custom category ID (overrides [category] if set).
  final String? customCategoryId;

  /// Display name for the category.
  final String name;

  /// Total amount spent in this category.
  final double amount;

  /// Amount from previous period for comparison (optional).
  final double? previousAmount;

  /// Color for the progress bar.
  final Color color;

  /// Icon for the category.
  final IconData icon;

  const CategoryBreakdownItem({
    this.category,
    this.customCategoryId,
    required this.name,
    required this.amount,
    this.previousAmount,
    required this.color,
    required this.icon,
  });

  /// Calculates the percent change from previous period.
  /// Returns null if no previous amount is available or if previous was zero.
  double? get percentChange {
    if (previousAmount == null || previousAmount! <= 0) {
      return null;
    }
    return ((amount - previousAmount!) / previousAmount!) * 100;
  }
}

/// A widget that displays spending breakdown by category.
///
/// Replaces the traditional donut chart with scannable horizontal bars,
/// following the Quiet Finance design philosophy.
///
/// Features:
/// - Sorted by amount (highest first)
/// - Progress bars proportional to spending
/// - Trend indicators showing change from previous period
/// - Tappable rows for drill-down
/// - "See all" button when items exceed [maxItems]
class CategoryBreakdownList extends StatelessWidget {
  /// List of category breakdown items to display.
  final List<CategoryBreakdownItem> items;

  /// Total amount for calculating bar proportions.
  final double totalAmount;

  /// Maximum number of items to show before "See all" (default: 5).
  final int maxItems;

  /// Callback when "See all" is tapped.
  final VoidCallback? onSeeAll;

  /// Callback when an item row is tapped.
  final Function(CategoryBreakdownItem)? onItemTap;

  const CategoryBreakdownList({
    super.key,
    required this.items,
    required this.totalAmount,
    this.maxItems = 5,
    this.onSeeAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Sort items by amount (highest first)
    final sortedItems = List<CategoryBreakdownItem>.from(items)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Limit to maxItems
    final displayItems = sortedItems.take(maxItems).toList();
    final hasMore = sortedItems.length > maxItems;

    // Find max amount for proportional bar widths
    final maxAmount =
        sortedItems.isNotEmpty ? sortedItems.first.amount : totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: LedgerifySpacing.lg),
          child: Text(
            'Spending by Category',
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),

        // Category rows
        ...displayItems.map(
          (item) => _CategoryRow(
            item: item,
            maxAmount: maxAmount,
            colors: colors,
            onTap: onItemTap != null ? () => onItemTap!(item) : null,
          ),
        ),

        // See all button
        if (hasMore && onSeeAll != null)
          Padding(
            padding: const EdgeInsets.only(top: LedgerifySpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: LedgerifySpacing.xs),
                  child: Text(
                    'See all \u2192',
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single row in the category breakdown list.
class _CategoryRow extends StatelessWidget {
  final CategoryBreakdownItem item;
  final double maxAmount;
  final LedgerifyColorScheme colors;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.item,
    required this.maxAmount,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LedgerifySpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: LedgerifyRadius.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name and amount with trend
              Row(
                children: [
                  // Category name
                  Expanded(
                    child: Text(
                      item.name,
                      style: LedgerifyTypography.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  LedgerifySpacing.horizontalSm,

                  // Amount
                  Text(
                    CurrencyFormatter.format(item.amount),
                    style: LedgerifyTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),

                  // Trend indicator
                  SizedBox(
                    width: 56,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _TrendIndicator(
                        percentChange: item.percentChange,
                        colors: colors,
                      ),
                    ),
                  ),
                ],
              ),

              LedgerifySpacing.verticalSm,

              // Progress bar
              _AnimatedProgressBar(
                progress: maxAmount > 0 ? item.amount / maxAmount : 0,
                color: item.color,
                backgroundColor: colors.surfaceHighlight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated horizontal progress bar.
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;

  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: LedgerifyRadius.borderRadiusFull,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: LedgerifyRadius.borderRadiusFull,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Trend indicator showing percent change.
class _TrendIndicator extends StatelessWidget {
  final double? percentChange;
  final LedgerifyColorScheme colors;

  const _TrendIndicator({
    required this.percentChange,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // No previous data
    if (percentChange == null) {
      return const SizedBox.shrink();
    }

    final change = percentChange!;
    final absChange = change.abs();

    // Small change (< 5%) shows dash
    if (absChange < 5) {
      return Text(
        '\u2014',
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.textTertiary,
        ),
      );
    }

    // Format percentage
    final percentText = '${absChange.toStringAsFixed(0)}%';

    // Up arrow (spending more) is bad (negative color)
    // Down arrow (spending less) is good (accent color)
    if (change > 0) {
      return Text(
        '\u2191$percentText',
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.negative,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    } else {
      return Text(
        '\u2193$percentText',
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.accent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }
  }
}
