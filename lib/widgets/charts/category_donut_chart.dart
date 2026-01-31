import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

/// Category Donut Chart - Ledgerify Design Language
///
/// An interactive donut chart showing category breakdown.
/// Tap a slice to expand it and show details in the center.
/// Follows the Quiet Finance philosophy: calm, professional, minimal.
class CategoryDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> breakdown;
  final double total;

  const CategoryDonutChart({
    super.key,
    required this.breakdown,
    required this.total,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Filter out zero amounts and sort by value (descending)
    final nonZeroEntries = widget.breakdown.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Empty state
    if (nonZeroEntries.isEmpty) {
      return _buildEmptyState(colors);
    }

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Chart with center text
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: PieChart(
                    PieChartData(
                      sections: _buildSections(nonZeroEntries, colors),
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      startDegreeOffset: -90, // Start from top
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = null;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Center text
                _buildCenterText(nonZeroEntries, colors),
              ],
            ),
          ),

          LedgerifySpacing.verticalLg,

          // Legend
          _buildLegend(nonZeroEntries, colors),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<ExpenseCategory, double>> entries,
    LedgerifyColorScheme colors,
  ) {
    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        value: entry.value,
        color: entry.key.color(context),
        radius: isTouched ? 28 : 24,
        showTitle: false,
        // Subtle border for touched section
        borderSide: isTouched
            ? BorderSide(
                color: colors.textPrimary.withValues(alpha: 0.3),
                width: 1,
              )
            : BorderSide.none,
      );
    }).toList();
  }

  Widget _buildCenterText(
    List<MapEntry<ExpenseCategory, double>> entries,
    LedgerifyColorScheme colors,
  ) {
    // If a slice is touched, show category details
    if (_touchedIndex != null &&
        _touchedIndex! >= 0 &&
        _touchedIndex! < entries.length) {
      final entry = entries[_touchedIndex!];
      final percentage =
          widget.total > 0 ? (entry.value / widget.total * 100) : 0.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.key.displayName,
            style: LedgerifyTypography.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(entry.value),
            style: LedgerifyTypography.amountMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      );
    }

    // Default: show total
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CurrencyFormatter.format(widget.total),
          style: LedgerifyTypography.amountMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'total spent',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(
    List<MapEntry<ExpenseCategory, double>> entries,
    LedgerifyColorScheme colors,
  ) {
    return Wrap(
      spacing: LedgerifySpacing.lg,
      runSpacing: LedgerifySpacing.sm,
      alignment: WrapAlignment.center,
      children: entries.map((entry) {
        final isTouched = entries.indexOf(entry) == _touchedIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              final index = entries.indexOf(entry);
              _touchedIndex = _touchedIndex == index ? null : index;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.key.color(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.key.displayName,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: isTouched ? colors.textPrimary : colors.textSecondary,
                  fontWeight: isTouched ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 48,
            color: colors.textTertiary,
          ),
          LedgerifySpacing.verticalMd,
          Text(
            'No expenses yet',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
