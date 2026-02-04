import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/income.dart';
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
import '../widgets/filter_sheet.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/unified_transaction_tile.dart';
import '../ui/components/empty_state.dart';
import 'add_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final RecurringExpenseService recurringService;
  final RecurringIncomeService recurringIncomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final CategoryDefaultService categoryDefaultService;
  final MerchantHistoryService merchantHistoryService;
  final IncomeService incomeService;
  final GoalService goalService;

  const TransactionsScreen({
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
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late DateTime _selectedMonth;

  String _searchQuery = '';
  ExpenseFilter _filter = ExpenseFilter.empty;
  TransactionFilter _transactionFilter = TransactionFilter.all;

  Timer? _debounceTimer;

  static const int _pageSize = 50;
  int _currentPage = 0;

  MonthSummary? _cachedExpenseSummary;
  IncomeSummary? _cachedIncomeSummary;
  List<UnifiedTransaction> _cachedTransactions = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();

    widget.expenseService.box.listenable().addListener(_onDataChanged);
    widget.incomeService.box.listenable().addListener(_onDataChanged);

    _updateCachedData();
  }

  @override
  void dispose() {
    widget.expenseService.box.listenable().removeListener(_onDataChanged);
    widget.incomeService.box.listenable().removeListener(_onDataChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onDataChanged() {
    _updateCachedData();
    if (mounted) setState(() {});
  }

  void _updateCachedData() {
    _cachedExpenseSummary = widget.expenseService.getMonthSummary(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    _cachedIncomeSummary = widget.incomeService.getMonthSummary(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    _cachedTransactions = _buildUnifiedTransactions(
      _cachedExpenseSummary!.expenses,
      _cachedIncomeSummary!.incomes,
    );
  }

  void _resetPagination() {
    _currentPage = 0;
  }

  void _loadMore() {
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

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month + 1, 0),
      helpText: 'Pick a date in the month',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _resetPagination();
      _updateCachedData();
    });
  }

  Future<void> _showQuickAddSheet() async {
    final action = await QuickAddSheet.show(
      context,
      expenseService: widget.expenseService,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case QuickAddAction.expense:
        await _navigateToAddExpense();
        break;
      case QuickAddAction.income:
        await AddIncomeSheet.show(
          context,
          incomeService: widget.incomeService,
          goalService: widget.goalService,
          recurringIncomeService: widget.recurringIncomeService,
        );
        break;
      case QuickAddAction.goal:
        await AddEditGoalSheet.show(
          context,
          goalService: widget.goalService,
        );
        break;
    }
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
                  _resetPagination();
                });
              }
            });
          },
          onFilterTap: _showFilterSheet,
          onTitleTap: _pickMonth,
        ),
        centerTitle: false,
      ),
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
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(LedgerifyColorScheme colors) {
    final expenseSummary = _cachedExpenseSummary;
    final incomeSummary = _cachedIncomeSummary;
    if (expenseSummary == null || incomeSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthExpenses = expenseSummary.expenses;
    final monthIncomes = incomeSummary.incomes;

    final hasSearchOrFilter =
        _searchQuery.isNotEmpty || _filter.hasActiveFilters;

    List<UnifiedTransaction> allTransactions = List.from(_cachedTransactions);
    allTransactions = _applyTransactionTypeFilter(allTransactions);

    List<UnifiedTransaction> displayTransactions;
    bool showLoadMore = false;

    if (hasSearchOrFilter) {
      displayTransactions = allTransactions;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        displayTransactions = displayTransactions.where((t) {
          final title = t.title.toLowerCase();
          final subtitle = t.subtitle.toLowerCase();
          return title.contains(query) || subtitle.contains(query);
        }).toList();
      }

      if (_filter.hasActiveFilters) {
        displayTransactions = displayTransactions.where((t) {
          if (t.type == TransactionType.expense) {
            return _filter.matches(t.asExpense);
          }
          return true;
        }).toList();
      }
    } else {
      final limit = (_currentPage + 1) * _pageSize;
      displayTransactions = allTransactions.take(limit).toList();
      showLoadMore = displayTransactions.length < allTransactions.length;
    }

    final noMatchingTransactions =
        hasSearchOrFilter && displayTransactions.isEmpty;
    final hasAnyData = monthExpenses.isNotEmpty || monthIncomes.isNotEmpty;

    return CustomScrollView(
      slivers: [
        if (hasAnyData)
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeaderDelegate(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                  vertical: LedgerifySpacing.sm,
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
          ),
        if (hasSearchOrFilter && displayTransactions.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildFilterIndicator(
              colors,
              displayTransactions.length,
              allTransactions.length,
            ),
          ),
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 88),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return EmptyState(
      title: 'No transactions this month',
      subtitle: 'Add income or expenses to start tracking',
      ctaLabel: 'Add transaction',
      onCtaTap: _showQuickAddSheet,
    );
  }

  Widget _buildNoMatchState(LedgerifyColorScheme colors) {
    final hasSearch = _searchQuery.isNotEmpty;
    final hasFilters = _filter.hasActiveFilters;

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

    return EmptyState(
      title: 'No results',
      subtitle: message,
      ctaLabel: 'Clear filters',
      onCtaTap: _clearFilters,
    );
  }

  Widget _buildFilterIndicator(
    LedgerifyColorScheme colors,
    int filteredCount,
    int totalCount,
  ) {
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
    final itemCount = transactions.length + (showLoadMore ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == transactions.length && showLoadMore) {
            return _buildLoadMoreButton(colors);
          }

          final transaction = transactions[index];
          final showDateHeader = index == 0 ||
              !_isSameDay(transaction.date, transactions[index - 1].date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          onPressed: _loadMore,
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

  List<UnifiedTransaction> _buildUnifiedTransactions(
    List<Expense> expenses,
    List<Income> incomes,
  ) {
    final transactions = <UnifiedTransaction>[];
    for (final expense in expenses) {
      transactions.add(UnifiedTransaction.fromExpense(expense));
    }
    for (final income in incomes) {
      transactions.add(UnifiedTransaction.fromIncome(income));
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

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
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = LedgerifyColors.of(context);
    return Container(
      color: colors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.divider),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
