import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/smart_insight.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/insight_service.dart';
import '../theme/ledgerify_theme.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/budget_setup_sheet.dart';
import '../widgets/category_breakdown_list.dart';
import '../widgets/compact_monthly_trend.dart';
import '../widgets/hero_metric_card.dart';
import '../widgets/smart_insight_card.dart';
import '../widgets/spending_pace_indicator.dart';

/// Analytics Screen - Ledgerify Design Language
///
/// Redesigned for "lazy-nerd-friendly" analytics:
/// - HeroMetricCard: "Am I okay?" in 2 seconds
/// - Smart insights: Auto-generated, actionable
/// - Spending pace: On track / behind pace
/// - Category breakdown: Horizontal bars with trends
/// - Compact monthly trend: 6-month mini chart
/// - Budget progress: Keep existing widget
///
/// Features swipeable month navigation.
class AnalyticsScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final BudgetService budgetService;
  final IncomeService incomeService;
  final InsightService? insightService;

  const AnalyticsScreen({
    super.key,
    required this.expenseService,
    required this.budgetService,
    required this.incomeService,
    this.insightService,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /// DateFormat for month display - static to avoid recreation on every build
  static final _monthFormat = DateFormat('MMMM yyyy');

  /// Short month names for labels - static const to avoid recreation
  static const _shortMonthNames = [
    '',
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

  /// Currently selected month for viewing analytics
  late DateTime _selectedMonth;

  /// Insight service for generating smart insights
  late final InsightService _insightService;

  /// Debounce timer for month navigation
  Timer? _monthChangeDebounce;

  @override
  void initState() {
    super.initState();
    // Start with current month
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    // Use provided insight service or create one
    _insightService = widget.insightService ??
        InsightService(
          expenseService: widget.expenseService,
          incomeService: widget.incomeService,
          budgetService: widget.budgetService,
        );
  }

  @override
  void dispose() {
    _monthChangeDebounce?.cancel();
    super.dispose();
  }

  /// Navigate to the previous month (debounced)
  void _goToPreviousMonth() {
    _monthChangeDebounce?.cancel();
    _monthChangeDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
          );
        });
      }
    });
  }

  /// Navigate to the next month (only if not in the future, debounced)
  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    _monthChangeDebounce?.cancel();
    _monthChangeDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted && !nextMonth.isAfter(DateTime(now.year, now.month))) {
        setState(() {
          _selectedMonth = nextMonth;
        });
      }
    });
  }

  /// Handle horizontal swipe gestures for month navigation
  void _handleHorizontalSwipe(DragEndDetails details) {
    // Minimum velocity threshold for swipe detection
    const velocityThreshold = 200.0;

    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! > velocityThreshold) {
      // Swipe right = go to previous month
      _goToPreviousMonth();
    } else if (details.primaryVelocity! < -velocityThreshold) {
      // Swipe left = go to next month
      _goToNextMonth();
    }
  }

  /// Check if the selected month is the current month
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  /// Check if we can navigate to the next month
  bool get _canGoToNextMonth {
    final now = DateTime.now();
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );
    return nextMonth.year < now.year ||
        (nextMonth.year == now.year && nextMonth.month <= now.month);
  }

  /// Calculate budget progress for all budgets in the selected month
  List<BudgetProgress> _calculateBudgetProgress(
    List<Budget> budgets,
    Map<ExpenseCategory, double> categorySpending,
    double totalSpending,
  ) {
    return budgets.map((budget) {
      final spent = budget.isOverallBudget
          ? totalSpending
          : categorySpending[budget.category] ?? 0;
      return widget.budgetService.calculateProgress(budget, spent);
    }).toList();
  }

  void _showAddBudgetSheet() async {
    await BudgetSetupSheet.show(
      context,
      budgetService: widget.budgetService,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  void _showEditBudgetSheet(Budget budget) async {
    await BudgetSetupSheet.show(
      context,
      budgetService: widget.budgetService,
      existingBudget: budget,
      year: budget.year,
      month: budget.month,
    );
  }

  /// Handle insight tap - show snackbar for now
  void _handleInsightTap(SmartInsight insight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tap to see ${insight.categoryName ?? 'related'} transactions',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build category breakdown items from expense data
  List<CategoryBreakdownItem> _buildCategoryBreakdownItems(
    BuildContext context,
    Map<ExpenseCategory, double> currentBreakdown,
    Map<ExpenseCategory, double> previousBreakdown,
  ) {
    final items = <CategoryBreakdownItem>[];

    for (final category in ExpenseCategory.values) {
      final amount = currentBreakdown[category];
      if (amount == null || amount == 0) continue;

      final previousAmount = previousBreakdown[category];

      items.add(CategoryBreakdownItem(
        category: category,
        name: category.displayName,
        amount: amount,
        previousAmount: previousAmount,
        color: category.color(context),
        icon: category.icon,
      ));
    }

    return items;
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
        title: _buildMonthNavigator(colors, _monthFormat),
        centerTitle: true,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalSwipe,
        behavior: HitTestBehavior.translucent,
        child: ValueListenableBuilder(
          valueListenable: widget.expenseService.box.listenable(),
          builder: (context, Box<Expense> expenseBox, _) {
            return ValueListenableBuilder(
              valueListenable: widget.incomeService.box.listenable(),
              builder: (context, Box<Income> incomeBox, _) {
                return ValueListenableBuilder(
                  valueListenable: widget.budgetService.box.listenable(),
                  builder: (context, Box<Budget> budgetBox, _) {
                    return _buildContent(colors);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the swipeable month navigator in the app bar
  Widget _buildMonthNavigator(
    LedgerifyColorScheme colors,
    DateFormat monthFormat,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left arrow (previous month)
        GestureDetector(
          onTap: _goToPreviousMonth,
          child: Padding(
            padding: const EdgeInsets.all(LedgerifySpacing.sm),
            child: Icon(
              Icons.chevron_left_rounded,
              color: colors.textSecondary,
              size: 24,
            ),
          ),
        ),

        LedgerifySpacing.horizontalSm,

        // Month label
        Text(
          monthFormat.format(_selectedMonth),
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),

        LedgerifySpacing.horizontalSm,

        // Right arrow (next month) - disabled if at current month
        GestureDetector(
          onTap: _canGoToNextMonth ? _goToNextMonth : null,
          child: Padding(
            padding: const EdgeInsets.all(LedgerifySpacing.sm),
            child: Icon(
              Icons.chevron_right_rounded,
              color: _canGoToNextMonth
                  ? colors.textSecondary
                  : colors.textTertiary.withValues(alpha: 0.3),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main scrollable content
  Widget _buildContent(LedgerifyColorScheme colors) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    // Current month data
    final expenseSummary = widget.expenseService.getMonthSummary(year, month);
    final incomeSummary = widget.incomeService.getMonthSummary(year, month);

    // Previous month for comparison
    final prevMonth = DateTime(year, month - 1);
    final prevExpenseSummary = widget.expenseService.getMonthSummary(
      prevMonth.year,
      prevMonth.month,
    );

    // Generate insights
    final insights = _insightService.generateInsights(year, month);

    // Category breakdown items with trends
    final categoryItems = _buildCategoryBreakdownItems(
      context,
      expenseSummary.breakdown,
      prevExpenseSummary.breakdown,
    );

    // Monthly totals for trend chart (6 months)
    final monthlyTotals = widget.expenseService.getMonthlyTotals(6);

    // Find the index of selected month in the trend data
    final selectedMonthIndex = monthlyTotals.indexWhere(
      (m) => m.year == year && m.month == month,
    );

    // Calculate average monthly spending (last 3 completed months) for pace indicator
    double avgSpending = 0;
    if (monthlyTotals.length >= 2) {
      // Exclude current month from average if we're viewing current month
      final totalsForAverage = _isCurrentMonth && monthlyTotals.length > 1
          ? monthlyTotals.sublist(0, monthlyTotals.length - 1).take(3)
          : monthlyTotals.take(3);

      if (totalsForAverage.isNotEmpty) {
        avgSpending =
            totalsForAverage.map((m) => m.total).reduce((a, b) => a + b) /
                totalsForAverage.length;
      }
    }

    // Budget data for the selected month
    final budgets = widget.budgetService.getAllBudgetsForMonth(year, month);
    final budgetProgressList = _calculateBudgetProgress(
      budgets,
      expenseSummary.breakdown,
      expenseSummary.total,
    );

    // Get month labels for hero card
    final currentMonthLabel = _shortMonthNames[month];
    final prevMonthLabel = _shortMonthNames[prevMonth.month];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        top: LedgerifySpacing.lg,
        bottom: LedgerifySpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Metric Card - "Am I okay?" in 2 seconds
          HeroMetricCard(
            totalIncome: incomeSummary.total,
            totalExpenses: expenseSummary.total,
            monthLabel: currentMonthLabel,
            previousMonthExpenses: prevExpenseSummary.total,
            comparisonMonthLabel: prevMonthLabel,
          ),

          LedgerifySpacing.verticalLg,

          // Smart Insights List (2-3 insights max)
          if (insights.isNotEmpty) ...[
            SmartInsightsList(
              insights: insights,
              onInsightTap: _handleInsightTap,
            ),
            LedgerifySpacing.verticalLg,
          ],

          // Spending Pace Indicator (only for current month)
          if (_isCurrentMonth && avgSpending > 0) ...[
            SpendingPaceIndicator(
              totalSpentThisMonth: expenseSummary.total,
              averageMonthlySpending: avgSpending,
              selectedMonth: _selectedMonth,
            ),
            LedgerifySpacing.verticalLg,
          ],

          // Category Breakdown List
          if (categoryItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: LedgerifyRadius.borderRadiusLg,
              ),
              child: CategoryBreakdownList(
                items: categoryItems,
                totalAmount: expenseSummary.total,
              ),
            ),
            LedgerifySpacing.verticalLg,
          ],

          // Compact Monthly Trend (6-month mini chart)
          if (monthlyTotals.isNotEmpty) ...[
            CompactMonthlyTrend(
              data: monthlyTotals,
              selectedMonthIndex: selectedMonthIndex >= 0
                  ? selectedMonthIndex
                  : monthlyTotals.length - 1,
            ),
            LedgerifySpacing.verticalLg,
          ],

          // Budget Progress Card (existing widget)
          BudgetProgressCard(
            budgetProgressList: budgetProgressList,
            onAddBudget: _showAddBudgetSheet,
            onEditBudget: _showEditBudgetSheet,
          ),
        ],
      ),
    );
  }
}
