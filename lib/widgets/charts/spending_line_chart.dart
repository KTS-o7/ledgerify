import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

/// Trend period options for the line chart
enum TrendPeriod {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  final String displayName;
  const TrendPeriod(this.displayName);
}

/// Spending Line Chart - Ledgerify Design Language
///
/// An interactive line chart with area fill showing spending trends.
/// Supports daily, weekly, and monthly views with toggle chips.
/// Follows the Quiet Finance philosophy: calm, professional, minimal.
class SpendingLineChart extends StatefulWidget {
  final ExpenseService expenseService;

  const SpendingLineChart({
    super.key,
    required this.expenseService,
  });

  @override
  State<SpendingLineChart> createState() => _SpendingLineChartState();
}

class _SpendingLineChartState extends State<SpendingLineChart>
    with SingleTickerProviderStateMixin {
  TrendPeriod _selectedPeriod = TrendPeriod.monthly;
  late AnimationController _animationController;
  late Animation<double> _animation;

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

  void _onPeriodChanged(TrendPeriod period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _animationController.reset();
      _animationController.forward();
    }
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
                Icons.show_chart_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              LedgerifySpacing.horizontalSm,
              Text(
                'Spending Trend',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),

          LedgerifySpacing.verticalLg,

          // Toggle chips
          _buildPeriodToggle(colors),

          LedgerifySpacing.verticalXl,

          // Chart
          _buildChart(colors),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(LedgerifyColorScheme colors) {
    return Row(
      children: TrendPeriod.values.map((period) {
        final isSelected = period == _selectedPeriod;
        return Padding(
          padding: EdgeInsets.only(
            right: period != TrendPeriod.monthly ? LedgerifySpacing.sm : 0,
          ),
          child: GestureDetector(
            onTap: () => _onPeriodChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.md,
                vertical: LedgerifySpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.surfaceHighlight,
                borderRadius: LedgerifyRadius.borderRadiusSm,
              ),
              child: Text(
                period.displayName,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: isSelected
                      ? colors.brightness == Brightness.dark
                          ? colors.background
                          : Colors.white
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(LedgerifyColorScheme colors) {
    final chartData = _getChartData();

    // Empty state: less than 2 data points
    if (chartData.spots.length < 2) {
      return _buildEmptyState(colors);
    }

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return RepaintBoundary(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _getAnimatedSpots(chartData.spots),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: colors.accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.accent.withValues(alpha: 0.2),
                          colors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData: _buildTitlesData(colors, chartData),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateGridInterval(chartData.maxY),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceElevated,
                    tooltipRoundedRadius: LedgerifyRadius.sm,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.md,
                      vertical: LedgerifySpacing.sm,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = chartData.labels[spot.x.toInt()];
                        return LineTooltipItem(
                          '$label\n${CurrencyFormatter.format(spot.y)}',
                          LedgerifyTypography.labelMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                minX: 0,
                maxX: (chartData.spots.length - 1).toDouble(),
                minY: 0,
                maxY: chartData.maxY * 1.1, // 10% padding at top
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
            ),
          );
        },
      ),
    );
  }

  List<FlSpot> _getAnimatedSpots(List<FlSpot> spots) {
    return spots.map((spot) {
      // Animate the y value based on animation progress
      return FlSpot(spot.x, spot.y * _animation.value);
    }).toList();
  }

  double _calculateGridInterval(double maxY) {
    if (maxY <= 0) return 1000;

    // Calculate a nice interval that gives us 4-5 grid lines
    final rawInterval = maxY / 4;

    // Round to a nice number (1, 2, 5, 10, 20, 50, 100, etc.)
    final magnitude = _getMagnitude(rawInterval);
    final normalized = rawInterval / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  double _getMagnitude(double value) {
    if (value <= 0) return 1;
    return double.parse(
        '1e${value.abs().toStringAsExponential().split('e').last}');
  }

  FlTitlesData _buildTitlesData(
      LedgerifyColorScheme colors, _ChartData chartData) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          interval: _calculateGridInterval(chartData.maxY),
          getTitlesWidget: (value, meta) {
            // Don't show 0 if we have other values
            if (value == 0 && chartData.maxY > 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: LedgerifySpacing.sm),
              child: Text(
                CurrencyFormatter.formatCompact(value),
                style: LedgerifyTypography.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: _calculateXAxisInterval(chartData.spots.length),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= chartData.labels.length) {
              return const SizedBox.shrink();
            }

            // Only show labels at calculated intervals
            final interval = _calculateXAxisInterval(chartData.labels.length);
            if (index % interval.toInt() != 0 &&
                index != chartData.labels.length - 1) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: LedgerifySpacing.sm),
              child: Text(
                chartData.labels[index],
                style: LedgerifyTypography.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _calculateXAxisInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    if (dataLength <= 15) return 3;
    if (dataLength <= 20) return 5;
    return (dataLength / 5).ceil().toDouble();
  }

  _ChartData _getChartData() {
    switch (_selectedPeriod) {
      case TrendPeriod.daily:
        return _getDailyData();
      case TrendPeriod.weekly:
        return _getWeeklyData();
      case TrendPeriod.monthly:
        return _getMonthlyData();
    }
  }

  _ChartData _getDailyData() {
    final now = DateTime.now();
    final dailySpending = widget.expenseService.getDailySpending(
      now.year,
      now.month,
    );

    final spots = <FlSpot>[];
    final labels = <String>[];

    // Only include days up to today
    final maxDay = now.day;

    for (var day = 1; day <= maxDay; day++) {
      final amount = dailySpending[day] ?? 0.0;
      spots.add(FlSpot((day - 1).toDouble(), amount));
      labels.add(day.toString());
    }

    final maxY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _ChartData(
      spots: spots,
      labels: labels,
      maxY: maxY == 0 ? 1000 : maxY,
    );
  }

  _ChartData _getWeeklyData() {
    final weeklyTotals = widget.expenseService.getWeeklySpending(12);

    final spots = <FlSpot>[];
    final labels = <String>[];
    final dateFormat = DateFormat('MMM d');

    for (var i = 0; i < weeklyTotals.length; i++) {
      final week = weeklyTotals[i];
      spots.add(FlSpot(i.toDouble(), week.total));
      labels.add(dateFormat.format(week.weekStart));
    }

    final maxY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _ChartData(
      spots: spots,
      labels: labels,
      maxY: maxY == 0 ? 1000 : maxY,
    );
  }

  _ChartData _getMonthlyData() {
    final monthlyTotals = widget.expenseService.getMonthlyTotals(6);

    final spots = <FlSpot>[];
    final labels = <String>[];
    final dateFormat = DateFormat('MMM');

    for (var i = 0; i < monthlyTotals.length; i++) {
      final month = monthlyTotals[i];
      spots.add(FlSpot(i.toDouble(), month.total));
      final date = DateTime(month.year, month.month);
      labels.add(dateFormat.format(date));
    }

    final maxY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _ChartData(
      spots: spots,
      labels: labels,
      maxY: maxY == 0 ? 1000 : maxY,
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
              Icons.timeline_rounded,
              size: 48,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'Need more data to show trends',
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

/// Internal data class for chart rendering
class _ChartData {
  final List<FlSpot> spots;
  final List<String> labels;
  final double maxY;

  const _ChartData({
    required this.spots,
    required this.labels,
    required this.maxY,
  });
}
