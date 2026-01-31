import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/recurring_expense.dart';
import '../services/recurring_expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Upcoming Recurring Card - Ledgerify Design Language
///
/// Shows the next 3 recurring expenses due within 14 days.
/// Provides quick visibility into upcoming payments from the home screen.
///
/// Features:
/// - Shows up to 3 items sorted by due date
/// - "View all" link to navigate to Recurring tab
/// - Tap item to edit
/// - Hidden when no upcoming items
class UpcomingRecurringCard extends StatelessWidget {
  final RecurringExpenseService recurringService;
  final VoidCallback onViewAll;
  final Function(RecurringExpense) onTapItem;

  const UpcomingRecurringCard({
    super.key,
    required this.recurringService,
    required this.onViewAll,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return ValueListenableBuilder(
      valueListenable: recurringService.box.listenable(),
      builder: (context, Box<RecurringExpense> box, _) {
        final upcoming =
            recurringService.getUpcoming(days: 14).take(3).toList();

        // Hide if no upcoming items
        if (upcoming.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LedgerifySpacing.lg,
                  LedgerifySpacing.lg,
                  LedgerifySpacing.md,
                  LedgerifySpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming',
                      style: LedgerifyTypography.headlineSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LedgerifySpacing.sm,
                          vertical: LedgerifySpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View all',
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List of upcoming items
              ...upcoming.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == upcoming.length - 1;

                return _UpcomingRecurringTile(
                  item: item,
                  onTap: () => onTapItem(item),
                  showDivider: !isLast,
                  colors: colors,
                );
              }),

              // Bottom padding
              const SizedBox(height: LedgerifySpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

/// Single tile for an upcoming recurring expense
class _UpcomingRecurringTile extends StatelessWidget {
  final RecurringExpense item;
  final VoidCallback onTap;
  final bool showDivider;
  final LedgerifyColorScheme colors;

  const _UpcomingRecurringTile({
    required this.item,
    required this.onTap,
    required this.showDivider,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceHighlight,
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    item.category.icon,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),

                const SizedBox(width: LedgerifySpacing.md),

                // Title and amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: LedgerifyTypography.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.amount),
                        style: LedgerifyTypography.amountSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Due date
                Text(
                  _formatDueDate(item.nextDueDate),
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: _getDueDateColor(item.nextDueDate),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Divider
        if (showDivider)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: LedgerifySpacing.lg),
            child: Divider(
              height: 1,
              color: colors.divider,
            ),
          ),
      ],
    );
  }

  /// Formats the due date in a user-friendly way
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final difference = dueDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      // Format as "Feb 1" style
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  /// Gets the color for the due date based on urgency
  Color _getDueDateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final difference = dueDate.difference(today).inDays;

    if (difference <= 1) {
      // Today or tomorrow - accent color for attention
      return colors.accent;
    } else {
      return colors.textTertiary;
    }
  }
}
