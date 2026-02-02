import 'package:flutter/material.dart';
import '../models/unified_recurring_item.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Unified Recurring Tile - Ledgerify Design Language
///
/// Displays a single recurring item (income or expense) with:
/// - Icon container (44x44dp, rounded)
/// - Title and frequency badge
/// - Amount with +/- prefix for income/expense
/// - Next date or "Paused" status
/// - Goal allocations (income only)
/// - Overflow menu with quick actions
/// - Swipe to delete with confirmation
///
/// Layout:
/// ┌───────────────────────────────────────────────────────────┐
/// │  [Icon]  Title                  Frequency      +/-Amount  │
/// │  [44x44] Next: Feb 5 / Paused                       [⋮]   │
/// │          → 2 goals allocated (income only, optional)      │
/// └───────────────────────────────────────────────────────────┘
class UnifiedRecurringTile extends StatelessWidget {
  final UnifiedRecurringItem item;
  final VoidCallback? onTap;
  final VoidCallback? onPayNow;
  final VoidCallback? onMarkReceived;
  final VoidCallback? onSkip;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;

  /// Current date (normalized to midnight) for due date calculations.
  /// Pass from parent to avoid redundant DateTime.now() calls when
  /// rendering multiple tiles.
  final DateTime? today;

  const UnifiedRecurringTile({
    super.key,
    required this.item,
    this.onTap,
    this.onPayNow,
    this.onMarkReceived,
    this.onSkip,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.today,
  });

  /// Shows the context menu bottom sheet with all available actions.
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
                  item.title,
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
                  onTap?.call();
                },
              ),
              // Pay Now / Mark Received option (only for active items)
              if (item.isActive) ...[
                if (item.isIncome && onMarkReceived != null)
                  ListTile(
                    leading:
                        Icon(Icons.check_circle_rounded, color: colors.accent),
                    title: Text(
                      'Mark Received',
                      style: LedgerifyTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onMarkReceived!();
                    },
                  ),
                if (!item.isIncome && onPayNow != null)
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
              ],
              // Skip option (only for active items)
              if (item.isActive && onSkip != null)
                ListTile(
                  leading: Icon(Icons.skip_next_rounded,
                      color: colors.textSecondary),
                  title: Text(
                    'Skip This Time',
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSkip!();
                  },
                ),
              // Pause/Resume option
              ListTile(
                leading: Icon(
                  item.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: colors.textSecondary,
                ),
                title: Text(
                  item.isActive ? 'Pause' : 'Resume',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (item.isActive) {
                    onPause?.call();
                  } else {
                    onResume?.call();
                  }
                },
              ),
              // Delete option
              if (onDelete != null)
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
                    _confirmDelete(context, colors);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a delete confirmation dialog.
  void _confirmDelete(BuildContext context, LedgerifyColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Delete Recurring ${item.isIncome ? 'Income' : 'Expense'}',
          style: LedgerifyTypography.headlineSmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: Text(
              'Delete',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.negative,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Use provided today or compute once per build
    final now = DateTime.now();
    final todayDate = today ?? DateTime(now.year, now.month, now.day);

    // Wrap in RepaintBoundary to isolate repaints from parent list
    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(item.id),
        direction: onDelete != null
            ? DismissDirection.endToStart
            : DismissDirection.none,
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
          _confirmDelete(context, colors);
          return false; // We handle deletion in the confirmation dialog
        },
        child: Opacity(
          opacity: item.isActive ? 1.0 : 0.6,
          child: InkWell(
            onTap: onTap,
            onLongPress: () => _showContextMenu(context, colors),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
                vertical: LedgerifySpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  _buildIconContainer(colors),

                  LedgerifySpacing.horizontalMd,

                  // Title, status, and goal info
                  Expanded(
                    child: _buildContentColumn(colors, todayDate),
                  ),

                  LedgerifySpacing.horizontalSm,

                  // Amount and frequency
                  _buildAmountColumn(colors),

                  // Overflow menu button
                  _buildOverflowButton(context, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the 44x44 icon container with appropriate styling.
  Widget _buildIconContainer(LedgerifyColorScheme colors) {
    // Income: accent at 15% opacity, Expense: surfaceHighlight
    final backgroundColor = item.isIncome
        ? colors.accent.withValues(alpha: 0.15)
        : colors.surfaceHighlight;

    // Income: accent icon color, Expense: textSecondary
    final iconColor = item.isIncome ? colors.accent : colors.textSecondary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Icon(
        item.icon,
        size: 24,
        color: iconColor,
      ),
    );
  }

  /// Builds the main content column with title, status, and goal info.
  Widget _buildContentColumn(LedgerifyColorScheme colors, DateTime todayDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        LedgerifySpacing.verticalXs,

        // Status row: Next date or Paused
        _buildStatusRow(colors, todayDate),

        // Goal allocations (income only, if present)
        if (item.isIncome && item.goalAllocationCount > 0) ...[
          LedgerifySpacing.verticalXs,
          _buildGoalAllocationRow(colors),
        ],
      ],
    );
  }

  /// Builds the status row showing next date or paused status.
  Widget _buildStatusRow(LedgerifyColorScheme colors, DateTime todayDate) {
    if (!item.isActive) {
      return Text(
        'Paused',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      );
    }

    final nextDate = DateTime(
      item.nextDate.year,
      item.nextDate.month,
      item.nextDate.day,
    );

    final difference = nextDate.difference(todayDate).inDays;
    final isDueSoon = difference <= 3;
    final isOverdue = difference < 0;

    String text;
    if (isOverdue) {
      text = item.isIncome ? 'Expected today' : 'Overdue';
    } else if (difference == 0) {
      text = item.isIncome ? 'Expected today' : 'Due today';
    } else if (difference == 1) {
      text = item.isIncome ? 'Expected tomorrow' : 'Due tomorrow';
    } else if (difference < 7) {
      text = item.isIncome
          ? 'Expected in $difference days'
          : 'Due in $difference days';
    } else {
      text = 'Next: ${_formatDate(nextDate, todayDate.year)}';
    }

    return Text(
      text,
      style: LedgerifyTypography.bodySmall.copyWith(
        color: isDueSoon || isOverdue ? colors.accent : colors.textTertiary,
      ),
    );
  }

  /// Builds the goal allocation indicator row.
  Widget _buildGoalAllocationRow(LedgerifyColorScheme colors) {
    final count = item.goalAllocationCount;
    final goalText = count == 1 ? '1 goal allocated' : '$count goals allocated';

    return Row(
      children: [
        Icon(
          Icons.arrow_forward_rounded,
          size: 12,
          color: colors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          goalText,
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Builds the amount column with frequency badge.
  Widget _buildAmountColumn(LedgerifyColorScheme colors) {
    // Format amount with prefix
    final amountText = item.isIncome
        ? '+${CurrencyFormatter.format(item.amount)}'
        : CurrencyFormatter.format(item.amount);

    // Amount color: income = accent, expense = textPrimary
    final amountColor = item.isIncome ? colors.accent : colors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Frequency badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: LedgerifyRadius.borderRadiusSm,
          ),
          child: Text(
            item.frequencyLabel,
            style: LedgerifyTypography.labelSmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ),

        LedgerifySpacing.verticalXs,

        // Amount
        Text(
          amountText,
          style: LedgerifyTypography.amountMedium.copyWith(
            color: amountColor,
          ),
        ),
      ],
    );
  }

  /// Builds the overflow menu button.
  Widget _buildOverflowButton(
      BuildContext context, LedgerifyColorScheme colors) {
    return IconButton(
      onPressed: () => _showContextMenu(context, colors),
      icon: Icon(
        Icons.more_vert_rounded,
        color: colors.textTertiary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      tooltip: 'More options',
    );
  }

  /// Formats a date as "Feb 5" or "Feb 5, 2027" if different year.
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
