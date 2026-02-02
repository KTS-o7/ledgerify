import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// CompactMonthlyTrend - Ledgerify Design Language
///
/// A compact 6-month trend visualization showing spending over time.
/// Follows the Quiet Finance philosophy: calm, professional, minimal.
///
/// Features:
/// - Mini bar chart with animated bars
/// - Month-over-month comparison
/// - Selected month highlighting
class CompactMonthlyTrend extends StatefulWidget {
  /// 6 months of spending data
  final List<MonthlyTotal> data;

  /// Which month is currently selected (for highlighting)
  final int selectedMonthIndex;

  const CompactMonthlyTrend({
    super.key,
    required this.data,
    required this.selectedMonthIndex,
  });

  @override
  State<CompactMonthlyTrend> createState() => _CompactMonthlyTrendState();
}

class _CompactMonthlyTrendState extends State<CompactMonthlyTrend>
    with SingleTickerProviderStateMixin {
  static final _monthFormat = DateFormat('MMM');

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
          // Header
          Text(
            'Monthly Trend',
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),

          LedgerifySpacing.verticalLg,

          // Content or empty state
          if (widget.data.length < 2)
            _buildEmptyState(colors)
          else
            _buildTrendContent(colors),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.xl),
      child: Center(
        child: Text(
          'Not enough data for trends',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendContent(LedgerifyColorScheme colors) {
    return Column(
      children: [
        // Month labels row
        Row(
          children: widget.data.map((month) {
            return Expanded(
              child: Center(
                child: Text(
                  _monthFormat.format(DateTime(month.year, month.month)),
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        LedgerifySpacing.verticalSm,

        // Mini bar chart
        _buildBarChart(colors),

        LedgerifySpacing.verticalSm,

        // Amount labels row
        Row(
          children: widget.data.map((month) {
            return Expanded(
              child: Center(
                child: Text(
                  _formatCompactAmount(month.total),
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        LedgerifySpacing.verticalMd,

        // Comparison text (right-aligned)
        _buildComparisonText(colors),
      ],
    );
  }

  Widget _buildBarChart(LedgerifyColorScheme colors) {
    // Find max for scaling
    final maxAmount =
        widget.data.map((m) => m.total).reduce((a, b) => a > b ? a : b);

    // Avoid division by zero
    final safeMax = maxAmount > 0 ? maxAmount : 1.0;

    const maxBarHeight = 48.0;
    const barWidth = 24.0;

    return SizedBox(
      height: maxBarHeight,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Row(
            children: List.generate(widget.data.length, (index) {
              final month = widget.data[index];
              final isSelected = index == widget.selectedMonthIndex;

              // Calculate bar height proportional to amount
              final heightRatio = month.total / safeMax;
              final barHeight = (heightRatio * maxBarHeight * _animation.value)
                  .clamp(2.0, maxBarHeight); // Minimum 2dp for visibility

              return Expanded(
                child: Center(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.accent
                            : colors.accent.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildComparisonText(LedgerifyColorScheme colors) {
    // Only show comparison if we have valid indices
    if (widget.selectedMonthIndex < 1 ||
        widget.selectedMonthIndex >= widget.data.length) {
      return const SizedBox.shrink();
    }

    final selectedMonth = widget.data[widget.selectedMonthIndex];
    final previousMonth = widget.data[widget.selectedMonthIndex - 1];

    // Get month labels
    final selectedLabel =
        _monthFormat.format(DateTime(selectedMonth.year, selectedMonth.month));
    final previousLabel =
        _monthFormat.format(DateTime(previousMonth.year, previousMonth.month));

    // Calculate percentage change
    if (previousMonth.total == 0) {
      // Can't calculate percentage change from zero
      return const SizedBox.shrink();
    }

    final change =
        ((selectedMonth.total - previousMonth.total) / previousMonth.total) *
            100;
    final isIncrease = change >= 0;
    final arrow = isIncrease ? '\u2191' : '\u2193'; // ↑ or ↓
    final percentText = '${change.abs().toStringAsFixed(0)}%';

    // Color: increase = negative (spending more), decrease = accent (spending less)
    final changeColor = isIncrease ? colors.negative : colors.accent;

    return Align(
      alignment: Alignment.centerRight,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$selectedLabel vs $previousLabel: ',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
            TextSpan(
              text: '$arrow$percentText',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format amount in compact form (e.g., "45K", "1.2L")
  String _formatCompactAmount(double amount) {
    // Use the existing compact formatter but strip the currency symbol
    // for this compact display
    final formatted = CurrencyFormatter.formatCompact(amount);
    // Remove the rupee symbol and any leading/trailing whitespace
    return formatted.replaceAll('\u20B9', '').trim();
  }
}
