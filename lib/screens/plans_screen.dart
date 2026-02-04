import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../services/goal_service.dart';
import '../services/income_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/recurring_income_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/budget_setup_sheet.dart';
import 'goals_screen.dart';
import 'recurring_list_screen.dart';

class PlansScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final IncomeService incomeService;
  final BudgetService budgetService;
  final RecurringExpenseService recurringExpenseService;
  final RecurringIncomeService recurringIncomeService;
  final GoalService goalService;

  const PlansScreen({
    super.key,
    required this.expenseService,
    required this.incomeService,
    required this.budgetService,
    required this.recurringExpenseService,
    required this.recurringIncomeService,
    required this.goalService,
  });

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _selectedMonth = next;
    });
  }

  Future<void> _addBudget() async {
    await BudgetSetupSheet.show(
      context,
      budgetService: widget.budgetService,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  void _addGoal() {
    AddEditGoalSheet.show(
      context,
      goalService: widget.goalService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final showAdd =
        _tabController.index == 0 /* Budgets */ || _tabController.index == 2;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Plans',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        actions: [
          if (showAdd)
            Padding(
              padding: const EdgeInsets.only(right: LedgerifySpacing.sm),
              child: IconButton(
                onPressed: _tabController.index == 0 ? _addBudget : _addGoal,
                icon: Container(
                  padding: const EdgeInsets.all(LedgerifySpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: LedgerifyRadius.borderRadiusSm,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: colors.background,
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accent,
          labelColor: colors.textPrimary,
          unselectedLabelColor: colors.textTertiary,
          labelStyle: LedgerifyTypography.labelLarge,
          tabs: const [
            Tab(text: 'Budgets'),
            Tab(text: 'Recurring'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetsTab(
            expenseService: widget.expenseService,
            budgetService: widget.budgetService,
            selectedMonth: _selectedMonth,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),
          RecurringListScreen(
            recurringExpenseService: widget.recurringExpenseService,
            recurringIncomeService: widget.recurringIncomeService,
            expenseService: widget.expenseService,
            incomeService: widget.incomeService,
            isEmbedded: true,
          ),
          GoalsScreen(
            goalService: widget.goalService,
            isEmbedded: true,
          ),
        ],
      ),
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  final ExpenseService expenseService;
  final BudgetService budgetService;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _BudgetsTab({
    required this.expenseService,
    required this.budgetService,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final listenable = Listenable.merge([
      budgetService.box.listenable(),
      expenseService.box.listenable(),
    ]);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final budgets =
            budgetService.getAllBudgetsForMonth(selectedMonth.year, selectedMonth.month);
        final summary =
            expenseService.getMonthSummary(selectedMonth.year, selectedMonth.month);

        final totalSpending = summary.total;
        final categorySpending = summary.breakdown;

        final progressList = budgets.map((budget) {
          final spent = budget.isOverallBudget
              ? totalSpending
              : categorySpending[budget.category] ?? 0;
          return budgetService.calculateProgress(budget, spent);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          children: [
            _MonthHeader(
              title: DateFormatter.formatMonthYear(selectedMonth),
              onPrevious: onPreviousMonth,
              onNext: onNextMonth,
            ),
            LedgerifySpacing.verticalLg,
            BudgetProgressCard(
              budgetProgressList: progressList,
              onAddBudget: () => BudgetSetupSheet.show(
                context,
                budgetService: budgetService,
                year: selectedMonth.year,
                month: selectedMonth.month,
              ),
              onEditBudget: (Budget budget) => BudgetSetupSheet.show(
                context,
                budgetService: budgetService,
                existingBudget: budget,
                year: selectedMonth.year,
                month: selectedMonth.month,
              ),
            ),
            LedgerifySpacing.verticalLg,
            if (budgets.isNotEmpty)
              Text(
                'Spent ${CurrencyFormatter.format(totalSpending)} this month',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left_rounded, color: colors.textSecondary),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            title,
            style: LedgerifyTypography.headlineSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}
