import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';

/// A collapsible card showing category-wise expense breakdown.
///
/// Shows:
/// - Each category with icon, name, amount, and percentage
/// - Sorted by amount (highest first)
/// - Collapsible to save space
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
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
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(List<MapEntry<ExpenseCategory, double>> entries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: entries.map((entry) {
          final percentage = widget.total > 0
              ? (entry.value / widget.total * 100)
              : 0.0;

          return _CategoryRow(
            category: entry.key,
            amount: entry.value,
            percentage: percentage,
          );
        }).toList(),
      ),
    );
  }
}

/// A single row in the category breakdown
class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(category.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),

          // Category name
          Expanded(
            child: Text(
              category.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Amount and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.entertainment:
        return Colors.purple;
      case ExpenseCategory.bills:
        return Colors.teal;
      case ExpenseCategory.health:
        return Colors.red;
      case ExpenseCategory.education:
        return Colors.indigo;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}
