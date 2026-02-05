import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/recurring_income.dart';
import '../models/unified_recurring_item.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/recurring_income_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/unified_recurring_tile.dart';
import 'add_recurring_screen.dart';

/// Unified Recurring List Screen - Ledgerify Design Language
///
/// Displays all recurring items (both income and expenses) with:
/// - Upcoming This Week section showing items due within 7 days
/// - Filter toggle (All/Income/Expenses)
/// - Active recurring items section
/// - Paused recurring items section
/// - Empty state when no recurring items exist
/// - FAB with action sheet to add income or expense
class RecurringListScreen extends StatefulWidget {
  final RecurringExpenseService recurringExpenseService;
  final RecurringIncomeService recurringIncomeService;
  final ExpenseService expenseService;
  final IncomeService incomeService;

  /// When true, removes back button (used when embedded in bottom nav)
  final bool isEmbedded;

  const RecurringListScreen({
    super.key,
    required this.recurringExpenseService,
    required this.recurringIncomeService,
    required this.expenseService,
    required this.incomeService,
    this.isEmbedded = false,
  });

  @override
  State<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends State<RecurringListScreen> {
  TransactionFilter _filter = TransactionFilter.all;

  // Cached data to avoid recomputation on every build
  List<UnifiedRecurringItem> _allUnifiedItems = [];
  List<UnifiedRecurringItem> _upcomingItems = [];
  List<UnifiedRecurringItem> _activeItems = [];
  List<UnifiedRecurringItem> _pausedItems = [];

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
    final recurringExpenses = widget.recurringExpenseService.getAll();
    final recurringIncomes =
        widget.recurringIncomeService.getAllRecurringIncomes();

    // Create unified items
    final allUnifiedItems = UnifiedRecurringItemFactory.fromLists(
      incomes: recurringIncomes,
      expenses: recurringExpenses,
      sortByNextDate: false,
    );

    // Compute upcoming items (within 7 days) - not affected by filter
    final upcomingItems = allUnifiedItems
        .where((item) => item.isActive && item.daysUntilNext <= 7)
        .toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

    // Separate all items into active and paused (sorted alphabetically)
    final activeItems = allUnifiedItems.where((item) => item.isActive).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final pausedItems = allUnifiedItems.where((item) => !item.isActive).toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    setState(() {
      _allUnifiedItems = allUnifiedItems;
      _upcomingItems = upcomingItems;
      _activeItems = activeItems;
      _pausedItems = pausedItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.isEmbedded,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
                color: colors.textPrimary,
              ),
        title: Text(
          'Recurring',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddTypeSheet(context, colors),
            color: colors.textPrimary,
          ),
        ],
      ),
      body: _buildContent(context, colors),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_recurring',
        onPressed: () => _showAddTypeSheet(context, colors),
        backgroundColor: colors.accent,
        foregroundColor: colors.background,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Builds the main content based on cached data.
  Widget _buildContent(BuildContext context, LedgerifyColorScheme colors) {
    if (_allUnifiedItems.isEmpty) {
      return _buildEmptyState(context, colors);
    }

    // Compute today once for all calculations
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Use cached upcoming items (take first 5 for display)
    final displayedUpcoming = _upcomingItems.take(5).toList();

    // Apply filter to cached active/paused items
    final filteredActiveItems = _applyFilter(_activeItems);
    final filteredPausedItems = _applyFilter(_pausedItems);

    return CustomScrollView(
      slivers: [
        // Upcoming This Week section
        if (displayedUpcoming.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildUpcomingSection(context, colors, displayedUpcoming,
                _upcomingItems.length, today),
          ),
          const SliverToBoxAdapter(child: LedgerifySpacing.verticalLg),
        ],

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.sm,
            ),
            child: TransactionFilterChips(
              selectedFilter: _filter,
              onFilterChanged: (filter) {
                setState(() {
                  _filter = filter;
                });
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: LedgerifySpacing.verticalMd),

        // Active section
        if (filteredActiveItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
                context, colors, 'Active', filteredActiveItems.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildUnifiedTile(context, filteredActiveItems[index], today),
              childCount: filteredActiveItems.length,
            ),
          ),
        ],

        // Paused section
        if (filteredPausedItems.isNotEmpty) ...[
          const SliverToBoxAdapter(child: LedgerifySpacing.verticalLg),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
                context, colors, 'Paused', filteredPausedItems.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildUnifiedTile(context, filteredPausedItems[index], today),
              childCount: filteredPausedItems.length,
            ),
          ),
        ],

        // Empty state when filter yields no results but items exist
        if (filteredActiveItems.isEmpty &&
            filteredPausedItems.isEmpty &&
            _allUnifiedItems.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildFilterEmptyState(colors),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 88),
        ),
      ],
    );
  }

  /// Applies the current filter to the list of items.
  List<UnifiedRecurringItem> _applyFilter(List<UnifiedRecurringItem> items) {
    switch (_filter) {
      case TransactionFilter.all:
        return items;
      case TransactionFilter.income:
        return items.where((item) => item.isIncome).toList();
      case TransactionFilter.expenses:
        return items.where((item) => item.isExpense).toList();
    }
  }

  /// Builds the "Upcoming This Week" card section.
  Widget _buildUpcomingSection(
    BuildContext context,
    LedgerifyColorScheme colors,
    List<UnifiedRecurringItem> items,
    int totalCount,
    DateTime today,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.lg),
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
              LedgerifySpacing.lg,
              LedgerifySpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UPCOMING THIS WEEK',
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
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
                    '$totalCount ${totalCount == 1 ? 'item' : 'items'}',
                    style: LedgerifyTypography.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return _buildUpcomingItemRow(context, colors, item, today, isLast);
          }),
        ],
      ),
    );
  }

  /// Builds a row for an upcoming item with quick action.
  Widget _buildUpcomingItemRow(
    BuildContext context,
    LedgerifyColorScheme colors,
    UnifiedRecurringItem item,
    DateTime today,
    bool isLast,
  ) {
    final daysUntil = item.daysUntilNext;
    String dueDateText;
    if (daysUntil < 0) {
      dueDateText = item.isIncome ? 'Expected today' : 'Overdue';
    } else if (daysUntil == 0) {
      dueDateText = item.isIncome ? 'Expected today' : 'Due today';
    } else if (daysUntil == 1) {
      dueDateText = item.isIncome ? 'Tomorrow' : 'Due tomorrow';
    } else {
      dueDateText =
          item.isIncome ? 'In $daysUntil days' : 'Due in $daysUntil days';
    }

    final dueDateColor = daysUntil < 0
        ? (item.isIncome ? colors.warning : colors.negative)
        : (daysUntil <= 1
            ? (item.isIncome ? colors.accent : colors.warning)
            : colors.textTertiary);

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: 1,
                ),
              ),
            ),
      child: InkWell(
        onTap: () => _navigateToEdit(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.md,
          ),
          child: Row(
            children: [
              // Type indicator (filled circle for income, outline for expense)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isIncome ? colors.accent : null,
                  border: item.isExpense
                      ? Border.all(color: colors.textTertiary, width: 1.5)
                      : null,
                ),
              ),
              LedgerifySpacing.horizontalMd,
              // Title
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
              LedgerifySpacing.horizontalMd,
              // Amount
              Text(
                CurrencyFormatter.format(item.amount),
                style: LedgerifyTypography.amountMedium.copyWith(
                  color: item.isIncome ? colors.accent : colors.negative,
                ),
              ),
              LedgerifySpacing.horizontalMd,
              // Due date text
              SizedBox(
                width: 80,
                child: Text(
                  dueDateText,
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: dueDateColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              LedgerifySpacing.horizontalSm,
              // Quick action button
              _buildQuickActionButton(context, colors, item),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the quick action button for upcoming items.
  Widget _buildQuickActionButton(
    BuildContext context,
    LedgerifyColorScheme colors,
    UnifiedRecurringItem item,
  ) {
    if (item.isIncome) {
      // Mark received button for income
      return SizedBox(
        width: 36,
        height: 28,
        child: TextButton(
          onPressed: () => _markReceived(context, item),
          style: TextButton.styleFrom(
            backgroundColor: colors.accent.withValues(alpha: 0.15),
            foregroundColor: colors.accent,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusSm,
            ),
          ),
          child: const Icon(Icons.check_rounded, size: 18),
        ),
      );
    } else {
      // Pay button for expense
      return SizedBox(
        width: 36,
        height: 28,
        child: TextButton(
          onPressed: () => _payNow(context, item),
          style: TextButton.styleFrom(
            backgroundColor: colors.surfaceHighlight,
            foregroundColor: colors.textSecondary,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusSm,
            ),
          ),
          child: Text(
            'Pay',
            style: LedgerifyTypography.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }
  }

  /// Builds the empty state view.
  Widget _buildEmptyState(BuildContext context, LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 64,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No recurring items',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Add subscriptions, bills, or regular income to track them automatically',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            LedgerifySpacing.verticalXl,
            ElevatedButton.icon(
              onPressed: () => _showAddTypeSheet(context, colors),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Recurring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.xl,
                  vertical: LedgerifySpacing.md,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an empty state when filter yields no results.
  Widget _buildFilterEmptyState(LedgerifyColorScheme colors) {
    final filterText = _filter == TransactionFilter.income
        ? 'recurring income'
        : 'recurring expenses';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 48,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'No $filterText',
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            TextButton(
              onPressed: () {
                setState(() {
                  _filter = TransactionFilter.all;
                });
              },
              child: Text(
                'Show all',
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header.
  Widget _buildSectionHeader(
    BuildContext context,
    LedgerifyColorScheme colors,
    String title,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: LedgerifyTypography.labelMedium.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          LedgerifySpacing.horizontalSm,
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
              count.toString(),
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a unified tile for a recurring item.
  Widget _buildUnifiedTile(
      BuildContext context, UnifiedRecurringItem item, DateTime today) {
    return UnifiedRecurringTile(
      item: item,
      today: today,
      onTap: () => _navigateToEdit(context, item),
      onPayNow: item.isExpense ? () => _payNow(context, item) : null,
      onMarkReceived: item.isIncome ? () => _markReceived(context, item) : null,
      onSkip: () => _skipItem(context, item),
      onPause: () => _pauseItem(context, item),
      onResume: () => _resumeItem(context, item),
      onDelete: () => _deleteItem(context, item),
    );
  }

  // ============================================
  // Navigation
  // ============================================

  /// Shows the add type selection sheet.
  void _showAddTypeSheet(BuildContext context, LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
              decoration: BoxDecoration(
                color: colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: LedgerifyRadius.borderRadiusFull,
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
                vertical: LedgerifySpacing.sm,
              ),
              child: Text(
                'Add Recurring',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            // Income option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: colors.accent,
                ),
              ),
              title: Text(
                'Recurring Income',
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Salary, freelance, dividends',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddIncome(context);
              },
            ),
            // Expense option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  Icons.trending_down_rounded,
                  color: colors.textSecondary,
                ),
              ),
              title: Text(
                'Recurring Expense',
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Subscriptions, rent, bills',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddExpense(context);
              },
            ),
            LedgerifySpacing.verticalLg,
          ],
        ),
      ),
    );
  }

  /// Navigates to add recurring income.
  void _navigateToAddIncome(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditRecurringIncomeSheet(
        recurringIncomeService: widget.recurringIncomeService,
        incomeService: widget.incomeService,
      ),
    );
  }

  /// Navigates to add recurring expense.
  void _navigateToAddExpense(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringScreen(
          recurringService: widget.recurringExpenseService,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recurring expense added',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: LedgerifyColors.of(context).accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Navigates to edit a recurring item.
  void _navigateToEdit(BuildContext context, UnifiedRecurringItem item) async {
    if (item.isIncome) {
      final recurringIncome = item.asRecurringIncome;
      if (recurringIncome != null) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddEditRecurringIncomeSheet(
            recurringIncomeService: widget.recurringIncomeService,
            incomeService: widget.incomeService,
            existingItem: recurringIncome,
          ),
        );
      }
    } else {
      final recurringExpense = item.asRecurringExpense;
      if (recurringExpense != null) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AddRecurringScreen(
              recurringService: widget.recurringExpenseService,
              recurringToEdit: recurringExpense,
            ),
          ),
        );

        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recurring expense updated',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: LedgerifyColors.of(context).accent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // ============================================
  // Actions
  // ============================================

  /// Pays a recurring expense now.
  void _payNow(BuildContext context, UnifiedRecurringItem item) async {
    final recurringExpense = item.asRecurringExpense;
    if (recurringExpense == null) return;

    final colors = LedgerifyColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final expense = await widget.recurringExpenseService.payNow(
      recurringExpense.id,
      widget.expenseService,
    );

    if (expense != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} paid - ${CurrencyFormatter.format(expense.amount)}',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Marks income as received.
  void _markReceived(BuildContext context, UnifiedRecurringItem item) async {
    final recurringIncome = item.asRecurringIncome;
    if (recurringIncome == null) return;

    final colors = LedgerifyColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Create income entry
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await widget.incomeService.addIncome(
      amount: recurringIncome.amount,
      source: recurringIncome.source,
      description: recurringIncome.description,
      date: today,
      goalAllocations: recurringIncome.goalAllocations,
      recurringIncomeId: recurringIncome.id,
    );

    // Advance the next date
    final nextDate = _calculateNextDate(today, recurringIncome.frequency);
    final updated = recurringIncome.copyWith(
      lastGeneratedDate: today,
      nextDate: nextDate,
    );
    await widget.recurringIncomeService.updateRecurringIncome(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} received - ${CurrencyFormatter.format(item.amount)}',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Skips the current occurrence without creating a transaction.
  void _skipItem(BuildContext context, UnifiedRecurringItem item) async {
    final colors = LedgerifyColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (item.isIncome) {
      final recurringIncome = item.asRecurringIncome;
      if (recurringIncome != null) {
        final nextDate = _calculateNextDate(today, recurringIncome.frequency);
        final updated = recurringIncome.copyWith(nextDate: nextDate);
        await widget.recurringIncomeService.updateRecurringIncome(updated);
      }
    } else {
      final recurringExpense = item.asRecurringExpense;
      if (recurringExpense != null) {
        final nextDate = widget.recurringExpenseService.calculateNextDueDate(
          recurringExpense,
          from: today,
        );
        final updated = recurringExpense.copyWith(nextDueDate: nextDate);
        await widget.recurringExpenseService.update(updated);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} skipped',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Pauses a recurring item.
  void _pauseItem(BuildContext context, UnifiedRecurringItem item) async {
    final colors = LedgerifyColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (item.isIncome) {
      await widget.recurringIncomeService.toggleActive(item.id);
    } else {
      await widget.recurringExpenseService.pause(item.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} paused',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            textColor: colors.accent,
            onPressed: () {
              if (item.isIncome) {
                widget.recurringIncomeService.toggleActive(item.id);
              } else {
                widget.recurringExpenseService.resume(item.id);
              }
            },
          ),
        ),
      );
    }
  }

  /// Resumes a paused recurring item.
  void _resumeItem(BuildContext context, UnifiedRecurringItem item) async {
    final colors = LedgerifyColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (item.isIncome) {
      await widget.recurringIncomeService.toggleActive(item.id);
    } else {
      await widget.recurringExpenseService.resume(item.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} resumed',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Deletes a recurring item (confirmation is handled in the tile).
  void _deleteItem(BuildContext context, UnifiedRecurringItem item) async {
    final title = item.title;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (item.isIncome) {
      await widget.recurringIncomeService.deleteRecurringIncome(item.id);
    } else {
      await widget.recurringExpenseService.delete(item.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$title deleted',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: LedgerifyColors.of(context).negative,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ============================================
  // Helpers
  // ============================================

  /// Calculates the next occurrence date based on frequency.
  DateTime _calculateNextDate(DateTime from, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return _addMonths(from, 1);
      case RecurrenceFrequency.yearly:
        return _addYears(from, 1);
      case RecurrenceFrequency.custom:
        return from.add(const Duration(days: 1));
    }
  }

  /// Adds months to a date, handling day overflow.
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

  /// Adds years to a date.
  DateTime _addYears(DateTime date, int years) {
    final newYear = date.year + years;
    final maxDay = DateTime(newYear, date.month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(newYear, date.month, day);
  }
}

/// A sheet for adding/editing recurring income.
/// This is a simplified version that reuses the pattern from RecurringIncomeScreen.
class AddEditRecurringIncomeSheet extends StatefulWidget {
  final RecurringIncomeService recurringIncomeService;
  final IncomeService incomeService;
  final RecurringIncome? existingItem;

  const AddEditRecurringIncomeSheet({
    super.key,
    required this.recurringIncomeService,
    required this.incomeService,
    this.existingItem,
  });

  @override
  State<AddEditRecurringIncomeSheet> createState() =>
      _AddEditRecurringIncomeSheetState();
}

class _AddEditRecurringIncomeSheetState
    extends State<AddEditRecurringIncomeSheet> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Schedule navigation for after the first frame, with guard to prevent duplicates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        Navigator.pop(context);
        // Show the actual add/edit sheet from RecurringIncomeScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _RecurringIncomeFormScreen(
              recurringIncomeService: widget.recurringIncomeService,
              existingItem: widget.existingItem,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// A simple form screen for recurring income (extracted from RecurringIncomeScreen pattern).
class _RecurringIncomeFormScreen extends StatefulWidget {
  final RecurringIncomeService recurringIncomeService;
  final RecurringIncome? existingItem;

  const _RecurringIncomeFormScreen({
    required this.recurringIncomeService,
    this.existingItem,
  });

  @override
  State<_RecurringIncomeFormScreen> createState() =>
      _RecurringIncomeFormScreenState();
}

class _RecurringIncomeFormScreenState
    extends State<_RecurringIncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  IncomeSource _selectedSource = IncomeSource.salary;
  RecurrenceFrequency _selectedFrequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  bool _isFormValid = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final item = widget.existingItem!;
      _amountController = TextEditingController(
        text: item.amount.toStringAsFixed(2),
      );
      _descriptionController = TextEditingController(
        text: item.description ?? '',
      );
      _selectedSource = item.source;
      _selectedFrequency = item.frequency;
      _startDate = item.nextDate;
    } else {
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
    }

    _amountController.addListener(_checkFormValidity);
    _checkFormValidity();
  }

  void _checkFormValidity() {
    final amount = double.tryParse(_amountController.text.trim());
    final newValid = amount != null && amount > 0;

    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_checkFormValidity);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final colors = LedgerifyColors.of(context);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.accent,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveRecurringIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      if (_isEditing) {
        final updated = widget.existingItem!.copyWith(
          amount: amount,
          source: _selectedSource,
          description: description.isNotEmpty ? description : null,
          frequency: _selectedFrequency,
          nextDate: _startDate,
          clearDescription: description.isEmpty,
        );
        await widget.recurringIncomeService.updateRecurringIncome(updated);
      } else {
        await widget.recurringIncomeService.createRecurringIncome(
          amount: amount,
          source: _selectedSource,
          description: description.isNotEmpty ? description : null,
          frequency: _selectedFrequency,
          nextDate: _startDate,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: colors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          color: colors.textPrimary,
        ),
        title: Text(
          _isEditing ? 'Edit Recurring Income' : 'Add Recurring Income',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                children: [
                  _buildAmountField(colors),
                  LedgerifySpacing.verticalXl,
                  _buildSourceDropdown(colors),
                  LedgerifySpacing.verticalXl,
                  _buildDescriptionField(colors),
                  LedgerifySpacing.verticalXl,
                  _buildFrequencyDropdown(colors),
                  LedgerifySpacing.verticalXl,
                  _buildDatePicker(colors),
                  LedgerifySpacing.verticalXl,
                  _buildSaveButton(colors),
                ],
              ),
            ),
    );
  }

  Widget _buildAmountField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: LedgerifyTypography.amountLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '\u20B9 ',
            prefixStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textSecondary,
            ),
            hintText: '0.00',
            hintStyle: LedgerifyTypography.amountLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value.trim());
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
          autofocus: !_isEditing,
        ),
      ],
    );
  }

  Widget _buildSourceDropdown(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        DropdownButtonFormField<IncomeSource>(
          initialValue: _selectedSource,
          dropdownColor: colors.surfaceElevated,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
          ),
          items: IncomeSource.values.map((source) {
            return DropdownMenuItem<IncomeSource>(
              value: source,
              child: Row(
                children: [
                  Icon(source.icon, size: 24, color: colors.textSecondary),
                  LedgerifySpacing.horizontalMd,
                  Text(source.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSource = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optional)',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _descriptionController,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown(LedgerifyColorScheme colors) {
    final frequencies = RecurrenceFrequency.values
        .where((f) => f != RecurrenceFrequency.custom)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        DropdownButtonFormField<RecurrenceFrequency>(
          initialValue: _selectedFrequency,
          dropdownColor: colors.surfaceElevated,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
          ),
          items: frequencies.map((freq) {
            return DropdownMenuItem<RecurrenceFrequency>(
              value: freq,
              child: Row(
                children: [
                  Icon(freq.icon, size: 24, color: colors.textSecondary),
                  LedgerifySpacing.horizontalMd,
                  Text(freq.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFrequency = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Next Date' : 'Start Date',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 24,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Text(
                  _formatDate(_startDate),
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(LedgerifyColorScheme colors) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isFormValid ? _saveRecurringIncome : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.background,
          disabledBackgroundColor: colors.surfaceHighlight,
          disabledForegroundColor: colors.textDisabled,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
        ),
        child: Text(
          _isEditing ? 'Update' : 'Add Recurring Income',
          style: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
