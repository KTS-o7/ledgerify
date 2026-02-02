import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/unified_recurring_item.dart';
import '../services/category_default_service.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/goal_service.dart';
import '../services/income_service.dart';
import '../services/merchant_history_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/recurring_income_service.dart';
import '../services/tag_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/add_income_sheet.dart';
import '../widgets/cash_flow_summary_card.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/spending_pace_card.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/unified_transaction_tile.dart';
import '../widgets/upcoming_recurring_card.dart';
import 'add_expense_screen.dart';
import 'add_recurring_screen.dart';

/// Home Screen - Ledgerify Design Language
///
/// The main screen showing:
/// - Monthly total summary card
/// - Category breakdown (collapsible)
/// - Expense list grouped by date
/// - FAB to add new expense
class HomeScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final RecurringExpenseService recurringService;
  final RecurringIncomeService recurringIncomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final CategoryDefaultService categoryDefaultService;
  final MerchantHistoryService merchantHistoryService;
  final IncomeService incomeService;
  final GoalService goalService;
  final VoidCallback? onNavigateToRecurring;

  const HomeScreen({
    super.key,
    required this.expenseService,
    required this.recurringService,
    required this.recurringIncomeService,
    required this.tagService,
    required this.customCategoryService,
    required this.categoryDefaultService,
    required this.merchantHistoryService,
    required this.incomeService,
    required this.goalService,
    this.onNavigateToRecurring,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;

  // Search and filter state
  String _searchQuery = '';
  ExpenseFilter _filter = ExpenseFilter.empty;

  // Transaction type filter state
  TransactionFilter _transactionFilter = TransactionFilter.all;

  // Debounce timer for search
  Timer? _debounceTimer;

  // Pagination state
  static const int _pageSize = 50;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _resetPagination() {
    _currentPage = 0;
  }

  /// Whether the selected month is the current month
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _resetPagination();
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        _resetPagination();
      });
    }
  }

  void _loadMoreExpenses() {
    setState(() {
      _currentPage++;
    });
  }

  Future<void> _showFilterSheet() async {
    final result = await FilterSheet.show(
      context,
      initialFilter: _filter,
      tagService: widget.tagService,
    );
    if (result != null) {
      setState(() {
        _filter = result;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filter = ExpenseFilter.empty;
    });
  }

  Future<void> _navigateToAddExpense([Expense? expenseToEdit]) async {
    final colors = LedgerifyColors.of(context);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expenseService: widget.expenseService,
          recurringService: widget.recurringService,
          tagService: widget.tagService,
          customCategoryService: widget.customCategoryService,
          categoryDefaultService: widget.categoryDefaultService,
          merchantHistoryService: widget.merchantHistoryService,
          expenseToEdit: expenseToEdit,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expenseToEdit != null ? 'Expense updated' : 'Expense added',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _navigateToEditRecurring(UnifiedRecurringItem item) async {
    if (item.isExpense && item.asRecurringExpense != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddRecurringScreen(
            recurringService: widget.recurringService,
            recurringToEdit: item.asRecurringExpense,
          ),
        ),
      );
    } else if (item.isIncome && item.asRecurringIncome != null) {
      // Navigate to recurring tab for income editing
      // (The recurring list screen has the proper UI for editing recurring income)
      widget.onNavigateToRecurring?.call();
    }
  }

  Future<void> _showQuickAddSheet() async {
    final action = await QuickAddSheet.show(
      context,
      expenseService: widget.expenseService,
    );
    // If action is null, either dismissed or template was used (expense already created)
    if (action == null || !mounted) return;

    switch (action) {
      case QuickAddAction.expense:
        // Navigate to AddExpenseScreen (existing logic)
        await _navigateToAddExpense();
        break;
      case QuickAddAction.income:
        // Show AddIncomeSheet
        await AddIncomeSheet.show(
          context,
          incomeService: widget.incomeService,
          goalService: widget.goalService,
          recurringIncomeService: widget.recurringIncomeService,
        );
        break;
      case QuickAddAction.goal:
        // Show AddEditGoalSheet
        await AddEditGoalSheet.show(
          context,
          goalService: widget.goalService,
        );
        break;
    }
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final colors = LedgerifyColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
        title: Text(
          'Delete Expense?',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this ${CurrencyFormatter.format(expense.amount)} expense?',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true && mounted) {
      await widget.expenseService.deleteExpense(expense.id);
      if (mounted) {
        final snackColors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense deleted',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: snackColors.textPrimary,
              ),
            ),
            backgroundColor: snackColors.surfaceElevated,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteIncome(Income income) async {
    final colors = LedgerifyColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
        title: Text(
          'Delete Income?',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this ${CurrencyFormatter.format(income.amount)} income? Any goal allocations will be reversed.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true && mounted) {
      await widget.incomeService.deleteIncome(income.id);
      if (mounted) {
        final snackColors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Income deleted',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: snackColors.textPrimary,
              ),
            ),
            backgroundColor: snackColors.surfaceElevated,
          ),
        );
      }
    }
  }

  /// Handles tapping on a unified transaction
  void _onTransactionTap(UnifiedTransaction transaction) {
    if (transaction.type == TransactionType.expense) {
      _navigateToAddExpense(transaction.asExpense);
    } else {
      AddIncomeSheet.show(
        context,
        incomeService: widget.incomeService,
        goalService: widget.goalService,
        recurringIncomeService: widget.recurringIncomeService,
        existingIncome: transaction.asIncome,
      );
    }
  }

  /// Handles deleting a unified transaction
  void _onTransactionDelete(UnifiedTransaction transaction) {
    if (transaction.type == TransactionType.expense) {
      _confirmDeleteExpense(transaction.asExpense);
    } else {
      _confirmDeleteIncome(transaction.asIncome);
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
        scrolledUnderElevation: 0,
        title: SearchFilterBar(
          title: DateFormatter.formatMonthYear(_selectedMonth),
          searchQuery: _searchQuery,
          hasActiveFilters: _filter.hasActiveFilters,
          onSearchChanged: (query) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _searchQuery = query;
                });
              }
            });
          },
          onFilterTap: _showFilterSheet,
        ),
        centerTitle: false,
      ),
      // FAB for quick expense access
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAddSheet,
        backgroundColor: colors.accent,
        foregroundColor: colors.background,
        elevation: 2,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        child: Icon(
          Icons.add_rounded,
          size: 28,
          color: colors.background,
        ),
      ),
      // Nested ValueListenableBuilders for expenses and income
      body: ValueListenableBuilder(
        valueListenable: widget.expenseService.box.listenable(),
        builder: (context, Box<Expense> expenseBox, _) {
          return ValueListenableBuilder(
            valueListenable: widget.incomeService.box.listenable(),
            builder: (context, Box<Income> incomeBox, _) {
              return _buildBody(context, colors);
            },
          );
        },
      ),
    );
  }

  /// Builds the main body content with unified transaction list
  Widget _buildBody(BuildContext context, LedgerifyColorScheme colors) {
    // Get expense data
    final expenseSummary = widget.expenseService.getMonthSummary(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final monthExpenses = expenseSummary.expenses;
    final totalExpenses = expenseSummary.total;
    final categoryBreakdown = expenseSummary.breakdown;

    // Get income data
    final incomeSummary = widget.incomeService.getMonthSummary(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final monthIncomes = incomeSummary.incomes;
    final totalIncome = incomeSummary.total;
    final incomeCount = incomeSummary.count;

    // Check if we're showing filtered results
    final hasSearchOrFilter =
        _searchQuery.isNotEmpty || _filter.hasActiveFilters;

    // Build unified transaction list
    List<UnifiedTransaction> allTransactions = _buildUnifiedTransactions(
      monthExpenses,
      monthIncomes,
    );

    // Apply transaction type filter
    allTransactions = _applyTransactionTypeFilter(allTransactions);

    // Apply search and filters
    List<UnifiedTransaction> displayTransactions;
    bool showLoadMore = false;
    final totalTransactionCount = allTransactions.length;

    if (hasSearchOrFilter) {
      // When searching/filtering, don't paginate - show all matching results
      displayTransactions = allTransactions;

      // Apply text search (title, subtitle)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        displayTransactions = displayTransactions.where((t) {
          final title = t.title.toLowerCase();
          final subtitle = t.subtitle.toLowerCase();
          return title.contains(query) || subtitle.contains(query);
        }).toList();
      }

      // Apply expense-specific filters (only on expenses)
      if (_filter.hasActiveFilters) {
        displayTransactions = displayTransactions.where((t) {
          if (t.type == TransactionType.expense) {
            return _filter.matches(t.asExpense);
          }
          // Income passes through filter (filters are expense-specific)
          return true;
        }).toList();
      }
    } else {
      // Use pagination when not searching/filtering
      final limit = (_currentPage + 1) * _pageSize;
      displayTransactions = allTransactions.take(limit).toList();

      // Check if there are more transactions to load
      showLoadMore = displayTransactions.length < totalTransactionCount;
    }

    final noMatchingTransactions =
        hasSearchOrFilter && displayTransactions.isEmpty;

    // Check if there's any data this month
    final hasAnyData = monthExpenses.isNotEmpty || monthIncomes.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // Cash Flow Summary Card (replaces MonthlySummaryCard)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
            ),
            child: CashFlowSummaryCard(
              selectedMonth: _selectedMonth,
              totalIncome: totalIncome,
              totalExpenses: totalExpenses,
              incomeCount: incomeCount,
              expenseCount: monthExpenses.length,
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
            ),
          ),
        ),

        // Spending Pace One-liner (only for current month with spending data)
        if (_isCurrentMonth && monthExpenses.isNotEmpty && !hasSearchOrFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: LedgerifySpacing.lg,
                right: LedgerifySpacing.lg,
                top: LedgerifySpacing.sm,
              ),
              child: Center(child: _buildSpendingPaceOneLiner()),
            ),
          ),

        // Spacing
        const SliverToBoxAdapter(
          child: LedgerifySpacing.verticalXl,
        ),

        // Upcoming Recurring Card (hide when searching/filtering)
        if (!hasSearchOrFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
              ),
              child: UpcomingRecurringCard(
                recurringExpenseService: widget.recurringService,
                recurringIncomeService: widget.recurringIncomeService,
                expenseService: widget.expenseService,
                incomeService: widget.incomeService,
                onViewAll: () {
                  // Navigate to Recurring tab
                  widget.onNavigateToRecurring?.call();
                },
                onTapItem: _navigateToEditRecurring,
                onExpensePaid: (recurring) {
                  // Show confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${recurring.title} paid',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      backgroundColor: colors.surfaceElevated,
                    ),
                  );
                },
                onIncomeReceived: (recurring) {
                  // Show confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${recurring.source.displayName} received - ${CurrencyFormatter.format(recurring.amount)}',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      backgroundColor: colors.surfaceElevated,
                    ),
                  );
                },
              ),
            ),
          ),

        // Spacing (only show if upcoming card is visible)
        if (!hasSearchOrFilter)
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalXl,
          ),

        // Category Breakdown Card (hide when searching/filtering)
        if (monthExpenses.isNotEmpty && !hasSearchOrFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
              ),
              child: CategoryDonutChart(
                breakdown: categoryBreakdown,
                total: totalExpenses,
              ),
            ),
          ),

        // Add Button (below donut chart)
        if (hasAnyData && !hasSearchOrFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: LedgerifySpacing.lg,
                right: LedgerifySpacing.lg,
                top: LedgerifySpacing.lg,
              ),
              child: _buildAddButton(colors),
            ),
          ),

        // Spacing before filter chips
        if (hasAnyData && !hasSearchOrFilter)
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalXl,
          ),

        // Transaction Filter Chips (All / Income / Expenses)
        if (hasAnyData)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
              ),
              child: TransactionFilterChips(
                selectedFilter: _transactionFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _transactionFilter = filter;
                    _resetPagination();
                  });
                },
              ),
            ),
          ),

        // Spacing after filter chips
        if (hasAnyData)
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalMd,
          ),

        // Active filter indicator
        if (hasSearchOrFilter && displayTransactions.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildFilterIndicator(
              colors,
              displayTransactions.length,
              totalTransactionCount,
            ),
          ),

        // Transaction List or Empty State
        if (!hasAnyData)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(colors),
          )
        else if (noMatchingTransactions)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNoMatchState(colors),
          )
        else
          _buildTransactionsList(displayTransactions, colors, showLoadMore),

        // Bottom padding (accounts for FAB)
        const SliverToBoxAdapter(
          child: SizedBox(height: 88), // 56dp FAB + 16dp margin + 16dp extra
        ),
      ],
    );
  }

  /// Builds a unified list of transactions from expenses and incomes
  List<UnifiedTransaction> _buildUnifiedTransactions(
    List<Expense> expenses,
    List<Income> incomes,
  ) {
    final transactions = <UnifiedTransaction>[];

    // Convert expenses to unified transactions
    for (final expense in expenses) {
      transactions.add(UnifiedTransaction.fromExpense(expense));
    }

    // Convert incomes to unified transactions
    for (final income in incomes) {
      transactions.add(UnifiedTransaction.fromIncome(income));
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  /// Applies the transaction type filter
  List<UnifiedTransaction> _applyTransactionTypeFilter(
    List<UnifiedTransaction> transactions,
  ) {
    switch (_transactionFilter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.income:
        return transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case TransactionFilter.expenses:
        return transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
    }
  }

  /// Builds the spending pace one-liner widget (only for current month)
  Widget? _buildSpendingPaceOneLiner() {
    // Only show for current month
    if (!_isCurrentMonth) return null;

    final pace = widget.expenseService.getSpendingPace(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Don't show if no historical data to compare
    if (pace == null) return null;

    return SpendingPaceOneLiner(pace: pace);
  }

  Widget _buildAddButton(LedgerifyColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _showQuickAddSheet,
        icon: Icon(
          Icons.add_rounded,
          color: colors.background,
          size: 24,
        ),
        label: Text(
          'Add',
          style: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.background,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.background,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No transactions this month',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Add income or expenses to start tracking',
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalXl,
            // Quick add button in empty state
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _showQuickAddSheet,
                icon: Icon(
                  Icons.add_rounded,
                  color: colors.background,
                  size: 20,
                ),
                label: Text(
                  'Add Transaction',
                  style: LedgerifyTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.background,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                    vertical: LedgerifySpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchState(LedgerifyColorScheme colors) {
    final hasSearch = _searchQuery.isNotEmpty;
    final hasFilters = _filter.hasActiveFilters;

    // Determine what type of transactions we're searching
    String typeLabel;
    switch (_transactionFilter) {
      case TransactionFilter.all:
        typeLabel = 'transactions';
        break;
      case TransactionFilter.income:
        typeLabel = 'income entries';
        break;
      case TransactionFilter.expenses:
        typeLabel = 'expenses';
        break;
    }

    String message;
    if (hasSearch && !hasFilters) {
      message = "No $typeLabel match '$_searchQuery'";
    } else if (!hasSearch && hasFilters) {
      message = 'No $typeLabel match your filters';
    } else {
      message = "No $typeLabel match '$_searchQuery' with current filters";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No results',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalXl,
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Clear filters',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterIndicator(
    LedgerifyColorScheme colors,
    int filteredCount,
    int totalCount,
  ) {
    // Determine label based on transaction filter
    String typeLabel;
    switch (_transactionFilter) {
      case TransactionFilter.all:
        typeLabel = 'transactions';
        break;
      case TransactionFilter.income:
        typeLabel = 'income entries';
        break;
      case TransactionFilter.expenses:
        typeLabel = 'expenses';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $filteredCount of $totalCount $typeLabel',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.sm,
                vertical: LedgerifySpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: LedgerifyRadius.borderRadiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colors.accent,
                  ),
                  LedgerifySpacing.horizontalXs,
                  Text(
                    'Clear',
                    style: LedgerifyTypography.labelSmall.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    List<UnifiedTransaction> transactions,
    LedgerifyColorScheme colors,
    bool showLoadMore,
  ) {
    // Calculate total item count: transactions + optional load more button
    final itemCount = transactions.length + (showLoadMore ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Load More button at the end
          if (index == transactions.length && showLoadMore) {
            return _buildLoadMoreButton(colors);
          }

          final transaction = transactions[index];
          final showDateHeader = index == 0 ||
              !_isSameDay(transaction.date, transactions[index - 1].date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.only(
                    left: LedgerifySpacing.lg,
                    right: LedgerifySpacing.lg,
                    top: LedgerifySpacing.lg,
                    bottom: LedgerifySpacing.sm,
                  ),
                  child: Text(
                    DateFormatter.formatRelative(transaction.date),
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              // Unified transaction tile
              UnifiedTransactionTile(
                transaction: transaction,
                onTap: () => _onTransactionTap(transaction),
                onDelete: () => _onTransactionDelete(transaction),
              ),
            ],
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _buildLoadMoreButton(LedgerifyColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xl,
      ),
      child: Center(
        child: TextButton(
          onPressed: _loadMoreExpenses,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.xl,
              vertical: LedgerifySpacing.md,
            ),
            backgroundColor: colors.surfaceHighlight,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
          ),
          child: Text(
            'Load More',
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
