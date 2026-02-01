import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/budget_setup_sheet.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/spending_line_chart.dart';

/// Analytics filter options for date range selection
enum AnalyticsFilter {
  thisMonth('This Month'),
  last3Months('Last 3 Months'),
  last6Months('Last 6 Months'),
  thisYear('This Year'),
  allTime('All Time');

  final String displayName;
  const AnalyticsFilter(this.displayName);
}

/// Analytics Screen - Ledgerify Design Language
///
/// Displays comprehensive spending analytics with:
/// - Budget progress overview with add/edit functionality
/// - Filter dropdown for date range selection
/// - Category breakdown donut chart
/// - Spending trend line chart with daily/weekly/monthly modes
/// - Monthly comparison bar chart
class AnalyticsScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final BudgetService budgetService;

  const AnalyticsScreen({
    super.key,
    required this.expenseService,
    required this.budgetService,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsFilter _selectedFilter = AnalyticsFilter.thisMonth;

  /// Calculates the date range based on selected filter
  ({DateTime start, DateTime end}) _getDateRange() {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case AnalyticsFilter.thisMonth:
        return (
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case AnalyticsFilter.last3Months:
        return (
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case AnalyticsFilter.last6Months:
        return (
          start: DateTime(now.year, now.month - 5, 1),
          end: now,
        );
      case AnalyticsFilter.thisYear:
        return (
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case AnalyticsFilter.allTime:
        return (
          start: DateTime(2000, 1, 1),
          end: now,
        );
    }
  }

  /// Calculate budget progress for all budgets in the current month
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
    final now = DateTime.now();
    await BudgetSetupSheet.show(
      context,
      budgetService: widget.budgetService,
      year: now.year,
      month: now.month,
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

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Analytics',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          _buildFilterDropdown(colors),
          const SizedBox(width: LedgerifySpacing.md),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.expenseService.box.listenable(),
        builder: (context, Box<Expense> expenseBox, _) {
          final dateRange = _getDateRange();
          final breakdown = widget.expenseService.getCategoryBreakdownForRange(
            dateRange.start,
            dateRange.end,
          );
          final total = breakdown.values.fold(0.0, (sum, value) => sum + value);

          // For budget progress, always use current month spending
          final currentMonthBreakdown =
              widget.expenseService.getCategoryBreakdownForRange(
            DateTime(now.year, now.month, 1),
            now,
          );
          final currentMonthTotal =
              currentMonthBreakdown.values.fold(0.0, (sum, v) => sum + v);

          return ValueListenableBuilder(
            valueListenable: widget.budgetService.box.listenable(),
            builder: (context, Box<Budget> budgetBox, _) {
              // Get budgets for current month
              final budgets = widget.budgetService.getAllBudgetsForMonth(
                now.year,
                now.month,
              );

              // Calculate progress
              final budgetProgressList = _calculateBudgetProgress(
                budgets,
                currentMonthBreakdown,
                currentMonthTotal,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: LedgerifySpacing.lg,
                  bottom: LedgerifySpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Progress Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.lg,
                      ),
                      child: BudgetProgressCard(
                        budgetProgressList: budgetProgressList,
                        onAddBudget: _showAddBudgetSheet,
                        onEditBudget: _showEditBudgetSheet,
                      ),
                    ),

                    LedgerifySpacing.verticalXl,

                    // Category Breakdown Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pie_chart_rounded,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          LedgerifySpacing.horizontalSm,
                          Text(
                            'Category Breakdown',
                            style: LedgerifyTypography.labelLarge.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    LedgerifySpacing.verticalMd,

                    // Category Breakdown Donut Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.lg,
                      ),
                      child: CategoryDonutChart(
                        breakdown: breakdown,
                        total: total,
                      ),
                    ),

                    LedgerifySpacing.verticalXl,

                    // Spending Trend Line Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.lg,
                      ),
                      child: SpendingLineChart(
                        expenseService: widget.expenseService,
                      ),
                    ),

                    LedgerifySpacing.verticalXl,

                    // Monthly Comparison Bar Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.lg,
                      ),
                      child: MonthlyBarChart(
                        expenseService: widget.expenseService,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the filter dropdown button using PopupMenuButton for better positioning
  Widget _buildFilterDropdown(LedgerifyColorScheme colors) {
    return PopupMenuButton<AnalyticsFilter>(
      initialValue: _selectedFilter,
      onSelected: (filter) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      offset: const Offset(0, 40), // Position menu below the button
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      color: colors.surfaceElevated,
      itemBuilder: (context) => AnalyticsFilter.values.map((filter) {
        final isSelected = filter == _selectedFilter;
        return PopupMenuItem<AnalyticsFilter>(
          value: filter,
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: colors.accent,
                  size: 18,
                )
              else
                const SizedBox(width: 18),
              LedgerifySpacing.horizontalSm,
              Text(
                filter.displayName,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: isSelected ? colors.accent : colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedFilter.displayName,
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.horizontalXs,
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
