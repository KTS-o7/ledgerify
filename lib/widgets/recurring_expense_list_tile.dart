import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/recurring_expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Recurring Expense List Tile - Ledgerify Design Language
///
/// Displays a single recurring expense entry with:
/// - Category icon in rounded container
/// - Title and frequency description
/// - Amount and next due date
/// - Pause/resume toggle button
/// - Swipe to delete action
class RecurringExpenseListTile extends StatelessWidget {
  final RecurringExpense recurring;
  final VoidCallback onTap;
  final VoidCallback onTogglePause;
  final VoidCallback onDelete;
  final VoidCallback? onPayNow;

  const RecurringExpenseListTile({
    super.key,
    required this.recurring,
    required this.onTap,
    required this.onTogglePause,
    required this.onDelete,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Dismissible(
      key: Key(recurring.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: LedgerifySpacing.xl),
        color: colors.negative,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion in the callback
      },
      child: Opacity(
        opacity: recurring.isActive ? 1.0 : 0.5,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
            child: Row(
              children: [
                // Category icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceHighlight,
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    recurring.category.icon,
                    size: 24,
                    color: colors.textSecondary,
                  ),
                ),

                SizedBox(width: LedgerifySpacing.md),

                // Title and frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recurring.title,
                              style: LedgerifyTypography.bodyLarge.copyWith(
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!recurring.isActive)
                            Container(
                              margin: const EdgeInsets.only(
                                  left: LedgerifySpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: LedgerifySpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceHighlight,
                                borderRadius: LedgerifyRadius.borderRadiusSm,
                              ),
                              child: Text(
                                'Paused',
                                style: LedgerifyTypography.labelSmall.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: LedgerifySpacing.xs),
                      Text(
                        recurring.frequencyDescription,
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: LedgerifySpacing.md),

                // Amount and next due
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(recurring.amount),
                      style: LedgerifyTypography.amountMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: LedgerifySpacing.xs),
                    Text(
                      _formatNextDue(recurring),
                      style: LedgerifyTypography.bodySmall.copyWith(
                        color: _isDueSoon(recurring)
                            ? colors.accent
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: LedgerifySpacing.sm),

                // Pay Now button (only for active items)
                if (recurring.isActive && onPayNow != null)
                  IconButton(
                    onPressed: onPayNow,
                    icon: Icon(
                      Icons.payment_rounded,
                      color: colors.accent,
                    ),
                    tooltip: 'Pay Now',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),

                // Pause/Resume button
                IconButton(
                  onPressed: onTogglePause,
                  icon: Icon(
                    recurring.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    color: recurring.isActive
                        ? colors.textTertiary
                        : colors.accent,
                  ),
                  tooltip: recurring.isActive ? 'Pause' : 'Resume',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formats the next due date in a user-friendly way.
  String _formatNextDue(RecurringExpense recurring) {
    if (!recurring.isActive) {
      return 'Paused';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      recurring.nextDueDate.year,
      recurring.nextDueDate.month,
      recurring.nextDueDate.day,
    );

    final difference = dueDate.difference(today).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      // Format as date
      return 'Due ${_formatDate(dueDate)}';
    }
  }

  /// Formats a date as "Jan 15" or "Jan 15, 2027" if different year.
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final months = [
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

    if (date.year == now.year) {
      return '${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  /// Checks if the recurring expense is due within 3 days.
  bool _isDueSoon(RecurringExpense recurring) {
    if (!recurring.isActive) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      recurring.nextDueDate.year,
      recurring.nextDueDate.month,
      recurring.nextDueDate.day,
    );

    final difference = dueDate.difference(today).inDays;
    return difference <= 3;
  }
}
