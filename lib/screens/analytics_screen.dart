import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
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
/// - Filter dropdown for date range selection
/// - Category breakdown donut chart
/// - Spending trend line chart with daily/weekly/monthly modes
/// - Monthly comparison bar chart
class AnalyticsScreen extends StatefulWidget {
  final ExpenseService expenseService;

  const AnalyticsScreen({
    super.key,
    required this.expenseService,
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

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

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
        builder: (context, Box<Expense> box, _) {
          final dateRange = _getDateRange();
          final breakdown = widget.expenseService.getCategoryBreakdownForRange(
            dateRange.start,
            dateRange.end,
          );
          final total = breakdown.values.fold(0.0, (sum, value) => sum + value);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
      ),
    );
  }

  /// Builds the filter dropdown button
  Widget _buildFilterDropdown(LedgerifyColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.md,
        vertical: LedgerifySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnalyticsFilter>(
          value: _selectedFilter,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
          dropdownColor: colors.surfaceElevated,
          borderRadius: LedgerifyRadius.borderRadiusMd,
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textPrimary,
          ),
          items: AnalyticsFilter.values.map((filter) {
            return DropdownMenuItem<AnalyticsFilter>(
              value: filter,
              child: Text(
                filter.displayName,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (filter) {
            if (filter != null) {
              setState(() {
                _selectedFilter = filter;
              });
            }
          },
        ),
      ),
    );
  }
}
