import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

/// Income vs Expense Chart - Ledgerify Design Language
///
/// A grouped bar chart comparing monthly income and expenses side by side.
/// Shows last 6 months with color-coded bars for income (accent) and expenses (negative).
/// Follows the Quiet Finance philosophy: calm, professional, minimal.
class IncomeExpenseChart extends StatefulWidget {
  final ExpenseService expenseService;
  final IncomeService incomeService;

  const IncomeExpenseChart({
    super.key,
    required this.expenseService,
    required this.incomeService,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedGroupIndex;

  // Cached data
  late List<_MonthlyComparison> _cachedData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _cachedData = _computeMonthlyData();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(IncomeExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseService != widget.expenseService ||
        oldWidget.incomeService != widget.incomeService) {
      _cachedData = _computeMonthlyData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<_MonthlyComparison> _computeMonthlyData() {
    final expenseTotals = widget.expenseService.getMonthlyTotals(6);
    final incomeTotals = widget.incomeService.getMonthlyTotals(6);

    final results = <_MonthlyComparison>[];

    for (int i = 0; i < expenseTotals.length; i++) {
      final expense = expenseTotals[i];
      final income = i < incomeTotals.length ? incomeTotals[i] : null;

      results.add(_MonthlyComparison(
        year: expense.year,
        month: expense.month,
        income: income?.total ?? 0,
        expense: expense.total,
      ));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and title
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              LedgerifySpacing.horizontalSm,
              Text(
                'Income vs Expenses',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalMd,

          // Legend
          _buildLegend(colors),

          LedgerifySpacing.verticalLg,

          // Chart
          _buildChart(colors),
        ],
      ),
    );
  }

  Widget _buildLegend(LedgerifyColorScheme colors) {
    return Row(
      children: [
        _LegendItem(
          color: colors.accent,
          label: 'Income',
          colors: colors,
        ),
        LedgerifySpacing.horizontalLg,
        _LegendItem(
          color: colors.negative,
          label: 'Expenses',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildChart(LedgerifyColorScheme colors) {
    final data = _cachedData;

    // Empty state
    if (data.isEmpty || data.every((m) => m.income == 0 && m.expense == 0)) {
      return _buildEmptyState(colors);
    }

    // Find max value for scaling
    double maxY = 0;
    for (final month in data) {
      if (month.income > maxY) maxY = month.income;
      if (month.expense > maxY) maxY = month.expense;
    }

    final now = DateTime.now();

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return RepaintBoundary(
            child: BarChart(
              BarChartData(
                barGroups: _buildBarGroups(colors, data, maxY, now),
                titlesData: _buildTitlesData(colors, data, now),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: _buildBarTouchData(colors, data),
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.15,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
            ),
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    LedgerifyColorScheme colors,
    List<_MonthlyComparison> data,
    double maxY,
    DateTime now,
  ) {
    return List.generate(data.length, (index) {
      final month = data[index];
      final isCurrentMonth = month.year == now.year && month.month == now.month;
      final isTouched = _touchedGroupIndex == index;

      // Animate bar heights
      final animatedIncome = month.income * _animation.value;
      final animatedExpense = month.expense * _animation.value;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          // Income bar
          BarChartRodData(
            toY: animatedIncome,
            color: isCurrentMonth
                ? colors.accent
                : colors.accent.withValues(alpha: 0.6),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: isTouched,
              toY: maxY * 1.1,
              color: colors.surfaceHighlight.withValues(alpha: 0.2),
            ),
          ),
          // Expense bar
          BarChartRodData(
            toY: animatedExpense,
            color: isCurrentMonth
                ? colors.negative
                : colors.negative.withValues(alpha: 0.6),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: isTouched,
              toY: maxY * 1.1,
              color: colors.surfaceHighlight.withValues(alpha: 0.2),
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0, 1] : [],
      );
    });
  }

  FlTitlesData _buildTitlesData(
    LedgerifyColorScheme colors,
    List<_MonthlyComparison> data,
    DateTime now,
  ) {
    final dateFormat = DateFormat('MMM');

    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= data.length) {
              return const SizedBox.shrink();
            }

            final month = data[index];
            final date = DateTime(month.year, month.month);
            final isCurrentMonth =
                month.year == now.year && month.month == now.month;

            return Padding(
              padding: const EdgeInsets.only(top: LedgerifySpacing.sm),
              child: Text(
                dateFormat.format(date),
                style: LedgerifyTypography.labelSmall.copyWith(
                  color:
                      isCurrentMonth ? colors.textPrimary : colors.textTertiary,
                  fontWeight:
                      isCurrentMonth ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  BarTouchData _buildBarTouchData(
    LedgerifyColorScheme colors,
    List<_MonthlyComparison> data,
  ) {
    return BarTouchData(
      enabled: true,
      touchCallback: (event, response) {
        setState(() {
          if (response == null || response.spot == null) {
            _touchedGroupIndex = null;
            return;
          }
          _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
        });
      },
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => colors.surfaceElevated,
        tooltipRoundedRadius: LedgerifyRadius.sm,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.sm,
        ),
        tooltipMargin: LedgerifySpacing.sm,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final month = data[groupIndex];
          final isIncome = rodIndex == 0;
          final value = isIncome ? month.income : month.expense;
          final label = isIncome ? 'Income' : 'Expense';

          return BarTooltipItem(
            '$label\n${CurrencyFormatter.format(value)}',
            LedgerifyTypography.labelSmall.copyWith(
              color: isIncome ? colors.accent : colors.negative,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 48,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'No data available',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalXs,
            Text(
              'Add income and expenses to see comparisons',
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final LedgerifyColorScheme colors;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        LedgerifySpacing.horizontalXs,
        Text(
          label,
          style: LedgerifyTypography.labelSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Internal class for monthly comparison data
class _MonthlyComparison {
  final int year;
  final int month;
  final double income;
  final double expense;

  const _MonthlyComparison({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  double get netIncome => income - expense;
  double get savingsRate =>
      income > 0 ? ((income - expense) / income) * 100 : 0;
}
