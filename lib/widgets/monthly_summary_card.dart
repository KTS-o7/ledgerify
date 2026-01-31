import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// A card widget displaying the monthly total with navigation arrows.
///
/// Shows:
/// - Current month/year
/// - Total expenses for the month
/// - Number of transactions
/// - Left/Right arrows to navigate between months
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                icon: const Icon(Icons.chevron_left),
                color: Colors.white,
                iconSize: 28,
              ),
              // Month/Year display
              Text(
                DateFormatter.formatMonthYear(selectedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Next month button
              IconButton(
                onPressed: _canGoNext ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right),
                color: _canGoNext ? Colors.white : Colors.white38,
                iconSize: 28,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total amount
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Expense count
          Text(
            expenseCount == 0
                ? 'No expenses'
                : expenseCount == 1
                ? '1 expense'
                : '$expenseCount expenses',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
