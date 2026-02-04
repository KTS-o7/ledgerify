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
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/spending_pace_card.dart';
import '../widgets/unified_transaction_tile.dart';
import '../widgets/upcoming_recurring_card.dart';
import '../ui/components/metric_row.dart';
import '../ui/components/section_card.dart';
import '../ui/components/empty_state.dart';
import '../ui/components/section_list_card.dart';
import 'add_expense_screen.dart';
import 'add_recurring_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final RecurringExpenseService recurringService;
  final RecurringIncomeService recurringIncomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final CategoryDefaultService categoryDefaultService;
  final MerchantHistoryService merchantHistoryService;
  final IncomeService incomeService;
  final GoalService goalService;

  final VoidCallback onNavigateToPlans;
  final VoidCallback onNavigateToTransactions;

  const DashboardScreen({
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
    required this.onNavigateToPlans,
    required this.onNavigateToTransactions,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedMonth;
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

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _updateCachedData();
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _updateCachedData();
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
      widget.onNavigateToPlans();
    }
  }

  Widget? _buildSpendingPaceOneLiner() {
    if (!_isCurrentMonth) return null;
    final pace = widget.expenseService.getSpendingPace(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    if (pace == null) return null;
    return SpendingPaceOneLiner(pace: pace);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    final expenseSummary = _cachedExpenseSummary;
    final incomeSummary = _cachedIncomeSummary;
    if (expenseSummary == null || incomeSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthExpenses = expenseSummary.expenses;
    final totalExpenses = expenseSummary.total;
    final breakdown = expenseSummary.breakdown;

    final monthIncomes = incomeSummary.incomes;
    final totalIncome = incomeSummary.total;
    final incomeCount = incomeSummary.count;

    final hasAnyData = monthExpenses.isNotEmpty || monthIncomes.isNotEmpty;
    final recentTransactions = _cachedTransactions.take(8).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Dashboard',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: widget.onNavigateToTransactions,
            icon: Icon(
              Icons.search_rounded,
              color: colors.textPrimary,
            ),
            tooltip: 'Search transactions',
          ),
        ],
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
              ),
              child: SectionCard(
                title: DateFormatter.formatMonthYear(_selectedMonth),
                onHeaderTap: _pickMonth,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: colors.textSecondary,
                      ),
                      tooltip: 'Previous month',
                    ),
                    IconButton(
                      onPressed: _isCurrentMonth ? null : _nextMonth,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _isCurrentMonth
                            ? colors.textDisabled
                            : colors.textSecondary,
                      ),
                      tooltip: 'Next month',
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetricRow(
                      left: MetricItem(
                        label: 'Income',
                        amount: totalIncome,
                        icon: Icons.arrow_downward_rounded,
                        showPlus: true,
                      ),
                      middle: MetricItem(
                        label: 'Spend',
                        amount: -totalExpenses,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      right: MetricItem(
                        label: 'Net',
                        amount: totalIncome - totalExpenses,
                        icon: Icons.savings_rounded,
                        showPlus: true,
                      ),
                    ),
                    LedgerifySpacing.verticalMd,
                    Text(
                      '${monthExpenses.length} expenses • $incomeCount incomes',
                      style: LedgerifyTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_buildSpendingPaceOneLiner() != null && hasAnyData)
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
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalXl,
          ),
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
                onViewAll: widget.onNavigateToPlans,
                onTapItem: _navigateToEditRecurring,
                onExpensePaid: (expense) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Paid ${expense.title} - ${CurrencyFormatter.format(expense.amount)}',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      backgroundColor: colors.surfaceElevated,
                    ),
                  );
                },
                onIncomeReceived: (income) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${income.source.displayName} received - ${CurrencyFormatter.format(income.amount)}',
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
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalXl,
          ),
          if (monthExpenses.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                ),
                child: CategoryDonutChart(
                  breakdown: breakdown,
                  total: totalExpenses,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: LedgerifySpacing.verticalXl,
          ),
          if (!hasAnyData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Start tracking',
                subtitle: 'Add your first expense or income to see insights here.',
                ctaLabel: 'Add transaction',
                onCtaTap: _showQuickAddSheet,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.lg),
                child: SectionListCard(
                  title: 'Recent',
                  trailing: TextButton(
                    onPressed: widget.onNavigateToTransactions,
                    child: Text(
                      'See all',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.accent,
                      ),
                    ),
                  ),
                  children: recentTransactions
                      .map(
                        (transaction) => UnifiedTransactionTile(
                          transaction: transaction,
                          onTap: () => _onTransactionTap(transaction),
                          onDelete: null,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 88),
          ),
        ],
      ),
    );
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
}
