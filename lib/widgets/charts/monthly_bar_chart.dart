import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

/// Monthly Bar Chart - Ledgerify Design Language
///
/// A bar chart comparing monthly spending totals.
/// Shows last 6 months with the current month highlighted.
/// Follows the Quiet Finance philosophy: calm, professional, minimal.
class MonthlyBarChart extends StatefulWidget {
  final ExpenseService expenseService;

  const MonthlyBarChart({
    super.key,
    required this.expenseService,
  });

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedBarIndex;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                Icons.bar_chart_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              LedgerifySpacing.horizontalSm,
              Text(
                'Monthly Comparison',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalXl,

          // Chart
          _buildChart(colors),
        ],
      ),
    );
  }

  Widget _buildChart(LedgerifyColorScheme colors) {
    final monthlyTotals = widget.expenseService.getMonthlyTotals(6);

    // Empty state: no data at all
    if (monthlyTotals.isEmpty ||
        monthlyTotals.every((month) => month.total == 0)) {
      return _buildEmptyState(colors);
    }

    final maxY =
        monthlyTotals.map((m) => m.total).reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return BarChart(
            BarChartData(
              barGroups: _buildBarGroups(colors, monthlyTotals, maxY, now),
              titlesData: _buildTitlesData(colors, monthlyTotals, now),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: _buildBarTouchData(colors, monthlyTotals),
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.15, // Extra space for amount labels
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    LedgerifyColorScheme colors,
    List<MonthlyTotal> monthlyTotals,
    double maxY,
    DateTime now,
  ) {
    return List.generate(monthlyTotals.length, (index) {
      final month = monthlyTotals[index];
      final isCurrentMonth = month.year == now.year && month.month == now.month;
      final isTouched = _touchedBarIndex == index;

      // Animate bar height from bottom
      final animatedValue = month.total * _animation.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animatedValue,
            color: isCurrentMonth
                ? colors.accent
                : colors.accent.withValues(alpha: 0.5),
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: isTouched,
              toY: maxY * 1.1,
              color: colors.surfaceHighlight.withValues(alpha: 0.3),
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    });
  }

  FlTitlesData _buildTitlesData(
    LedgerifyColorScheme colors,
    List<MonthlyTotal> monthlyTotals,
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
            if (index < 0 || index >= monthlyTotals.length) {
              return const SizedBox.shrink();
            }

            final month = monthlyTotals[index];
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
    List<MonthlyTotal> monthlyTotals,
  ) {
    return BarTouchData(
      enabled: true,
      touchCallback: (event, response) {
        setState(() {
          if (response == null || response.spot == null) {
            _touchedBarIndex = null;
            return;
          }
          _touchedBarIndex = response.spot!.touchedBarGroupIndex;
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
          final month = monthlyTotals[groupIndex];
          return BarTooltipItem(
            CurrencyFormatter.format(month.total),
            LedgerifyTypography.labelMedium.copyWith(
              color: colors.textPrimary,
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
              Icons.bar_chart_rounded,
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
          ],
        ),
      ),
    );
  }
}
