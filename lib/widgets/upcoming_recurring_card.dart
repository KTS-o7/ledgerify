import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_expense.dart';
import '../models/recurring_income.dart';
import '../models/unified_recurring_item.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/recurring_income_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Upcoming Recurring Card - Ledgerify Design Language
///
/// Shows the next 3-5 recurring items (both income and expenses) due within 14 days.
/// Provides quick visibility into upcoming payments and expected income from the home screen.
///
/// Features:
/// - Shows up to 5 items sorted by due date (soonest first)
/// - Badge shows count of items due this week
/// - "View all" link to navigate to Recurring tab
/// - Type indicator: filled circle for income, outline for expense
/// - Quick actions: checkmark for income (mark received), Pay for expense
/// - Hidden when no upcoming items
class UpcomingRecurringCard extends StatefulWidget {
  final RecurringExpenseService recurringExpenseService;
  final RecurringIncomeService recurringIncomeService;
  final ExpenseService? expenseService;
  final IncomeService? incomeService;
  final VoidCallback onViewAll;
  final Function(UnifiedRecurringItem) onTapItem;
  final Function(RecurringExpense)? onExpensePaid;
  final Function(RecurringIncome)? onIncomeReceived;

  const UpcomingRecurringCard({
    super.key,
    required this.recurringExpenseService,
    required this.recurringIncomeService,
    this.expenseService,
    this.incomeService,
    required this.onViewAll,
    required this.onTapItem,
    this.onExpensePaid,
    this.onIncomeReceived,
  });

  @override
  State<UpcomingRecurringCard> createState() => _UpcomingRecurringCardState();
}

class _UpcomingRecurringCardState extends State<UpcomingRecurringCard> {
  // Cached data to avoid recomputation on every build
  List<UnifiedRecurringItem> _upcomingItems = [];
  int _thisWeekCount = 0;
  DateTime _today = DateTime.now();

  // Box listeners for reactive updates
  VoidCallback? _expenseBoxListener;
  VoidCallback? _incomeBoxListener;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _setupListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  /// Sets up Hive box listeners for reactive updates
  void _setupListeners() {
    _expenseBoxListener = () => _refreshData();
    _incomeBoxListener = () => _refreshData();

    widget.recurringExpenseService.box
        .listenable()
        .addListener(_expenseBoxListener!);
    widget.recurringIncomeService.box
        .listenable()
        .addListener(_incomeBoxListener!);
  }

  /// Removes Hive box listeners
  void _removeListeners() {
    if (_expenseBoxListener != null) {
      widget.recurringExpenseService.box
          .listenable()
          .removeListener(_expenseBoxListener!);
    }
    if (_incomeBoxListener != null) {
      widget.recurringIncomeService.box
          .listenable()
          .removeListener(_incomeBoxListener!);
    }
  }

  /// Refreshes all cached data from services
  void _refreshData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(const Duration(days: 14));

    // Get upcoming expenses
    final upcomingExpenses =
        widget.recurringExpenseService.getUpcoming(days: 14);

    // Get upcoming income (filter active items due within 14 days)
    final upcomingIncome =
        widget.recurringIncomeService.getActiveRecurringIncomes().where((item) {
      final nextDate = DateTime(
        item.nextDate.year,
        item.nextDate.month,
        item.nextDate.day,
      );
      return !nextDate.isAfter(endDate);
    }).toList();

    // Convert to unified items
    final items = UnifiedRecurringItemFactory.fromLists(
      incomes: upcomingIncome,
      expenses: upcomingExpenses,
      sortByNextDate: true,
    );

    // Calculate this week count
    final thisWeekCount =
        widget.recurringExpenseService.getUpcomingCount(days: 7) +
            widget.recurringIncomeService.getUpcomingCount(days: 7);

    setState(() {
      _upcomingItems = items.take(5).toList();
      _thisWeekCount = thisWeekCount;
      _today = today;
    });
  }

  /// Handles paying an expense now
  Future<void> _handlePayExpense(
      BuildContext context, RecurringExpense expense) async {
    if (widget.expenseService == null) return;

    final generatedExpense = await widget.recurringExpenseService
        .payNow(expense.id, widget.expenseService!);
    if (generatedExpense != null && widget.onExpensePaid != null) {
      widget.onExpensePaid!(expense);
    }
  }

  /// Handles marking income as received
  Future<void> _handleMarkReceived(
      BuildContext context, RecurringIncome income) async {
    if (widget.incomeService == null) return;

    // Create the income entry
    await widget.incomeService!.addIncome(
      amount: income.amount,
      source: income.source,
      description: income.description,
      date: DateTime.now(),
      goalAllocations: income.goalAllocations,
      recurringIncomeId: income.id,
    );

    // Advance the next date
    final nextDate = _calculateNextDate(income.nextDate, income.frequency);
    final updated = income.copyWith(
      nextDate: nextDate,
      lastGeneratedDate: DateTime.now(),
    );
    await widget.recurringIncomeService.updateRecurringIncome(updated);

    if (widget.onIncomeReceived != null) {
      widget.onIncomeReceived!(income);
    }
  }

  /// Calculates the next occurrence date based on frequency
  DateTime _calculateNextDate(DateTime from, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return _addMonths(from, 1);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
      case RecurrenceFrequency.custom:
        return from.add(const Duration(days: 1));
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Hide if no upcoming items
    if (_upcomingItems.isEmpty) {
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
                Row(
                  children: [
                    Text(
                      'Upcoming',
                      style: LedgerifyTypography.headlineSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (_thisWeekCount > 0) ...[
                      LedgerifySpacing.horizontalMd,
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
                          '$_thisWeekCount this week',
                          style: LedgerifyTypography.labelSmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.sm,
                      vertical: LedgerifySpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: colors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of upcoming items
          ..._upcomingItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _upcomingItems.length - 1;

            return _UnifiedUpcomingTile(
              item: item,
              onTap: () => widget.onTapItem(item),
              onQuickAction: item.isExpense
                  ? (widget.expenseService != null
                      ? () =>
                          _handlePayExpense(context, item.asRecurringExpense!)
                      : null)
                  : (widget.incomeService != null
                      ? () =>
                          _handleMarkReceived(context, item.asRecurringIncome!)
                      : null),
              showDivider: !isLast,
              colors: colors,
              today: _today,
            );
          }),

          // Bottom padding
          LedgerifySpacing.verticalSm,
        ],
      ),
    );
  }
}

/// Single tile for an upcoming recurring item (income or expense)
class _UnifiedUpcomingTile extends StatelessWidget {
  final UnifiedRecurringItem item;
  final VoidCallback onTap;
  final VoidCallback? onQuickAction;
  final bool showDivider;
  final LedgerifyColorScheme colors;
  final DateTime today;

  const _UnifiedUpcomingTile({
    required this.item,
    required this.onTap,
    this.onQuickAction,
    required this.showDivider,
    required this.colors,
    required this.today,
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
                // Type indicator (filled circle for income, outline for expense)
                _buildTypeIndicator(),

                LedgerifySpacing.horizontalMd,

                // Title and due description
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
                        _formatDueDate(item.nextDate),
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color: _getDueDateColor(item.nextDate),
                        ),
                      ),
                    ],
                  ),
                ),

                LedgerifySpacing.horizontalSm,

                // Amount with appropriate color/prefix
                Text(
                  _formatAmount(),
                  style: LedgerifyTypography.amountSmall.copyWith(
                    color: item.isIncome ? colors.accent : colors.textPrimary,
                  ),
                ),

                // Quick action button
                if (onQuickAction != null) ...[
                  LedgerifySpacing.horizontalSm,
                  _buildQuickActionButton(),
                ],
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

  /// Builds the type indicator (filled or outline circle)
  Widget _buildTypeIndicator() {
    if (item.isIncome) {
      // Filled circle for income
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.15),
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: Icon(
          item.icon,
          size: 20,
          color: colors.accent,
        ),
      );
    } else {
      // Outline style for expense
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: Icon(
          item.icon,
          size: 20,
          color: colors.textSecondary,
        ),
      );
    }
  }

  /// Builds the quick action button
  Widget _buildQuickActionButton() {
    if (item.isIncome) {
      // Checkmark for income (mark as received)
      return IconButton(
        onPressed: onQuickAction,
        icon: Icon(
          Icons.check_circle_outline_rounded,
          size: 22,
          color: colors.accent,
        ),
        tooltip: 'Mark Received',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      );
    } else {
      // Pay button for expense
      return TextButton(
        onPressed: onQuickAction,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.sm,
            vertical: LedgerifySpacing.xs,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Pay',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.accent,
          ),
        ),
      );
    }
  }

  /// Formats the amount with appropriate prefix
  String _formatAmount() {
    if (item.isIncome) {
      return '+${CurrencyFormatter.format(item.amount)}';
    } else {
      return CurrencyFormatter.format(item.amount);
    }
  }

  /// Formats the due date in a user-friendly way
  String _formatDueDate(DateTime date) {
    final dueDate = DateTime(date.year, date.month, date.day);
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
      return 'Due ${months[date.month - 1]} ${date.day}';
    }
  }

  /// Gets the color for the due date based on urgency
  Color _getDueDateColor(DateTime date) {
    final dueDate = DateTime(date.year, date.month, date.day);
    final difference = dueDate.difference(today).inDays;

    if (difference < 0) {
      // Overdue - use negative/warning color
      return colors.negative;
    } else if (difference <= 1) {
      // Today or tomorrow - accent color for attention
      return colors.accent;
    } else {
      return colors.textTertiary;
    }
  }
}
