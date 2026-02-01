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

  void _showContextMenu(BuildContext context, LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: LedgerifySpacing.md),
                decoration: BoxDecoration(
                  color: colors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                  vertical: LedgerifySpacing.sm,
                ),
                child: Text(
                  recurring.title,
                  style: LedgerifyTypography.headlineSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Edit option
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.textSecondary),
                title: Text(
                  'Edit',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              // Pay Now option (only for active)
              if (recurring.isActive && onPayNow != null)
                ListTile(
                  leading: Icon(Icons.payment_rounded, color: colors.accent),
                  title: Text(
                    'Pay Now',
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onPayNow!();
                  },
                ),
              // Pause/Resume option
              ListTile(
                leading: Icon(
                  recurring.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: colors.textSecondary,
                ),
                title: Text(
                  recurring.isActive ? 'Pause' : 'Resume',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTogglePause();
                },
              ),
              // Delete option
              ListTile(
                leading: Icon(Icons.delete_rounded, color: colors.negative),
                title: Text(
                  'Delete',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.negative,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          onLongPress: () => _showContextMenu(context, colors),
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

                LedgerifySpacing.horizontalMd,

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
                      LedgerifySpacing.verticalXs,
                      Text(
                        recurring.frequencyDescription,
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                LedgerifySpacing.horizontalMd,

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
                    LedgerifySpacing.verticalXs,
                    _buildDueDateText(colors),
                  ],
                ),

                LedgerifySpacing.horizontalSm,

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

  /// Builds the due date text widget with computed values.
  Widget _buildDueDateText(LedgerifyColorScheme colors) {
    if (!recurring.isActive) {
      return Text(
        'Paused',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      recurring.nextDueDate.year,
      recurring.nextDueDate.month,
      recurring.nextDueDate.day,
    );

    final difference = dueDate.difference(today).inDays;
    final isDueSoon = difference <= 3;

    String text;
    if (difference < 0) {
      text = 'Overdue';
    } else if (difference == 0) {
      text = 'Due today';
    } else if (difference == 1) {
      text = 'Due tomorrow';
    } else if (difference < 7) {
      text = 'Due in $difference days';
    } else {
      text = 'Due ${_formatDate(dueDate, now.year)}';
    }

    return Text(
      text,
      style: LedgerifyTypography.bodySmall.copyWith(
        color: isDueSoon ? colors.accent : colors.textTertiary,
      ),
    );
  }

  /// Formats a date as "Jan 15" or "Jan 15, 2027" if different year.
  static const _months = [
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

  String _formatDate(DateTime date, int currentYear) {
    if (date.year == currentYear) {
      return '${_months[date.month - 1]} ${date.day}';
    } else {
      return '${_months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
