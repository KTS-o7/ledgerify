import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/recurring_expense.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/goal_service.dart';
import '../services/income_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/tag_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/add_income_sheet.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/search_filter_bar.dart';
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
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final IncomeService incomeService;
  final GoalService goalService;
  final VoidCallback? onNavigateToRecurring;

  const HomeScreen({
    super.key,
    required this.expenseService,
    required this.recurringService,
    required this.tagService,
    required this.customCategoryService,
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

  Future<void> _navigateToEditRecurring(RecurringExpense recurring) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringScreen(
          recurringService: widget.recurringService,
          recurringToEdit: recurring,
        ),
      ),
    );
  }

  Future<void> _showQuickAddSheet() async {
    final action = await QuickAddSheet.show(context);
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

  Future<void> _confirmDelete(Expense expense) async {
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
      body: ValueListenableBuilder(
        valueListenable: widget.expenseService.box.listenable(),
        builder: (context, Box<Expense> box, _) {
          // Single-pass retrieval of all month data
          final summary = widget.expenseService.getMonthSummary(
            _selectedMonth.year,
            _selectedMonth.month,
          );
          final monthExpenses = summary.expenses;
          final monthTotal = summary.total;
          final categoryBreakdown = summary.breakdown;

          // Check if we're showing filtered results
          final hasSearchOrFilter =
              _searchQuery.isNotEmpty || _filter.hasActiveFilters;

          // Apply search and filters, or use pagination
          List<Expense> displayExpenses;
          bool showLoadMore = false;
          final totalExpenseCount = monthExpenses.length;

          if (hasSearchOrFilter) {
            // When searching/filtering, don't paginate - show all matching results
            displayExpenses = monthExpenses;

            // Apply text search (merchant, note)
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              displayExpenses = displayExpenses.where((e) {
                final merchant = e.merchant?.toLowerCase() ?? '';
                final note = e.note?.toLowerCase() ?? '';
                return merchant.contains(query) || note.contains(query);
              }).toList();
            }

            // Apply filters
            if (_filter.hasActiveFilters) {
              displayExpenses =
                  displayExpenses.where((e) => _filter.matches(e)).toList();
            }
          } else {
            // Use pagination when not searching/filtering
            final limit = (_currentPage + 1) * _pageSize;
            displayExpenses =
                widget.expenseService.getExpensesForMonthPaginated(
              _selectedMonth.year,
              _selectedMonth.month,
              limit: limit,
              offset: 0,
            );

            // Check if there are more expenses to load
            showLoadMore = displayExpenses.length < totalExpenseCount;
          }

          final noMatchingExpenses =
              hasSearchOrFilter && displayExpenses.isEmpty;

          return CustomScrollView(
            slivers: [
              // Monthly Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                  ),
                  child: MonthlySummaryCard(
                    selectedMonth: _selectedMonth,
                    total: monthTotal,
                    expenseCount: monthExpenses.length,
                    onPreviousMonth: _previousMonth,
                    onNextMonth: _nextMonth,
                  ),
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
                      recurringService: widget.recurringService,
                      expenseService: widget.expenseService,
                      onViewAll: () {
                        // Navigate to Recurring tab
                        widget.onNavigateToRecurring?.call();
                      },
                      onTapItem: _navigateToEditRecurring,
                      onPayNow: (recurring, expense) {
                        // Show confirmation snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${recurring.title} paid - ${CurrencyFormatter.format(expense.amount)}',
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
                      total: monthTotal,
                    ),
                  ),
                ),

              // Spacing
              if (monthExpenses.isNotEmpty && !hasSearchOrFilter)
                const SliverToBoxAdapter(
                  child: LedgerifySpacing.verticalXl,
                ),

              // Active filter indicator
              if (hasSearchOrFilter && displayExpenses.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFilterIndicator(
                    colors,
                    displayExpenses.length,
                    monthExpenses.length,
                  ),
                ),

              // Expense List or Empty State
              if (monthExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(colors),
                )
              else if (noMatchingExpenses)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNoMatchState(colors),
                )
              else
                _buildExpenseList(displayExpenses, colors, showLoadMore),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 88),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAddSheet,
        backgroundColor: colors.accent,
        child: Icon(Icons.add_rounded, color: colors.background),
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
              Icons.receipt_long_outlined,
              size: 80,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No expenses this month',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Add your first expense to start tracking',
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
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

    String message;
    if (hasSearch && !hasFilters) {
      message = "No expenses match '$_searchQuery'";
    } else if (!hasSearch && hasFilters) {
      message = 'No expenses match your filters';
    } else {
      message = "No expenses match '$_searchQuery' with current filters";
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $filteredCount of $totalCount expenses',
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

  Widget _buildExpenseList(
    List<Expense> expenses,
    LedgerifyColorScheme colors,
    bool showLoadMore,
  ) {
    // Calculate total item count: expenses + optional load more button
    final itemCount = expenses.length + (showLoadMore ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Load More button at the end
          if (index == expenses.length && showLoadMore) {
            return _buildLoadMoreButton(colors);
          }

          final expense = expenses[index];
          final showDateHeader =
              index == 0 || !_isSameDay(expense.date, expenses[index - 1].date);

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
                    DateFormatter.formatRelative(expense.date),
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              // Expense tile
              ExpenseListTile(
                expense: expense,
                onTap: () => _navigateToAddExpense(expense),
                onDelete: () => _confirmDelete(expense),
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
