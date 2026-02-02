import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Spending Pace Indicator - Ledgerify Design Language
///
/// Shows if the user is on track for the month based on their
/// spending compared to their 3-month average.
///
/// Displays:
/// - Progress bar with time marker and spending fill
/// - Status text (on track / ahead / behind)
/// - Projected remaining amount
class SpendingPaceIndicator extends StatelessWidget {
  final double totalSpentThisMonth;
  final double averageMonthlySpending;
  final DateTime selectedMonth;
  final int? currentDay;

  const SpendingPaceIndicator({
    super.key,
    required this.totalSpentThisMonth,
    required this.averageMonthlySpending,
    required this.selectedMonth,
    this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Hide widget if no average data
    if (averageMonthlySpending <= 0) {
      return const SizedBox.shrink();
    }

    final paceData = _calculatePaceData();

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          LedgerifySpacing.verticalMd,
          _buildProgressBar(colors, paceData),
          LedgerifySpacing.verticalSm,
          _buildStatusText(colors, paceData),
        ],
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Text(
      'Spending Pace',
      style: LedgerifyTypography.labelLarge.copyWith(
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildProgressBar(LedgerifyColorScheme colors, _PaceData paceData) {
    return Column(
      children: [
        SizedBox(
          height: 8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final timeMarkerPosition = maxWidth * paceData.timeProgress;
              final spendingWidth =
                  maxWidth * paceData.spendingProgress.clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background
                  Container(
                    width: maxWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.surfaceHighlight,
                      borderRadius: LedgerifyRadius.borderRadiusFull,
                    ),
                  ),
                  // Spending fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: spendingWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(paceData.status, colors),
                      borderRadius: LedgerifyRadius.borderRadiusFull,
                    ),
                  ),
                  // Time marker
                  if (paceData.isCurrentMonth)
                    Positioned(
                      left: timeMarkerPosition - 4,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        LedgerifySpacing.verticalXs,
        // Day label
        if (paceData.isCurrentMonth)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Day ${paceData.dayOfMonth}',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusText(LedgerifyColorScheme colors, _PaceData paceData) {
    // Too early to predict
    if (paceData.isCurrentMonth && paceData.dayOfMonth <= 2) {
      return Text(
        'Too early to predict',
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      );
    }

    // Build status text based on pace
    final statusText = _getStatusText(paceData, colors);
    return statusText;
  }

  Widget _getStatusText(_PaceData paceData, LedgerifyColorScheme colors) {
    final statusColor = _getStatusColor(paceData.status, colors);
    final String statusLabel;
    final String detailText;

    switch (paceData.status) {
      case _PaceStatus.onTrack:
        statusLabel = 'On track';
        final amountLeft = paceData.amountLeftAtPace.abs();
        detailText =
            ' — ${CurrencyFormatter.format(amountLeft)} left at current pace';
      case _PaceStatus.aheadOfPace:
        statusLabel = 'Ahead of pace';
        final savings =
            (averageMonthlySpending - paceData.projectedTotal).abs();
        detailText =
            ' — saving ${CurrencyFormatter.format(savings)} this month';
      case _PaceStatus.behindPace:
        statusLabel = 'Behind pace';
        final overAmount =
            (paceData.projectedTotal - averageMonthlySpending).abs();
        detailText =
            ' — ${CurrencyFormatter.format(overAmount)} over at current rate';
    }

    // For past months, adjust the text
    if (!paceData.isCurrentMonth) {
      return _buildPastMonthStatus(paceData, colors);
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: statusLabel,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: detailText,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastMonthStatus(
      _PaceData paceData, LedgerifyColorScheme colors) {
    final statusColor = _getStatusColor(paceData.status, colors);
    final String statusLabel;
    final String detailText;
    final difference = (totalSpentThisMonth - averageMonthlySpending).abs();

    if (totalSpentThisMonth < averageMonthlySpending * 0.9) {
      statusLabel = 'Under budget';
      detailText = ' — saved ${CurrencyFormatter.format(difference)}';
    } else if (totalSpentThisMonth > averageMonthlySpending * 1.1) {
      statusLabel = 'Over budget';
      detailText = ' — spent ${CurrencyFormatter.format(difference)} extra';
    } else {
      statusLabel = 'On target';
      detailText = ' — within average spending';
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: statusLabel,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: detailText,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(_PaceStatus status, LedgerifyColorScheme colors) {
    switch (status) {
      case _PaceStatus.onTrack:
        return colors.accent;
      case _PaceStatus.aheadOfPace:
        return colors.accent;
      case _PaceStatus.behindPace:
        return colors.negative;
    }
  }

  _PaceData _calculatePaceData() {
    final now = DateTime.now();
    final year = selectedMonth.year;
    final month = selectedMonth.month;

    // Calculate days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Check if selected month is current month
    final isCurrentMonth = year == now.year && month == now.month;

    // Day of month for calculations
    final dayOfMonth = isCurrentMonth ? (currentDay ?? now.day) : daysInMonth;

    // Time progress (what percentage of month has elapsed)
    final timeProgress = dayOfMonth / daysInMonth;

    // Spending progress (what percentage of typical spending has been used)
    final spendingProgress = totalSpentThisMonth / averageMonthlySpending;

    // Projected end-of-month total
    final projectedTotal =
        dayOfMonth > 0 ? (totalSpentThisMonth / dayOfMonth) * daysInMonth : 0.0;

    // Amount "left" if following average pace
    final amountLeftAtPace = averageMonthlySpending - projectedTotal;

    // Determine status
    final _PaceStatus status;
    if (projectedTotal < averageMonthlySpending * 0.9) {
      status = _PaceStatus.aheadOfPace;
    } else if (projectedTotal > averageMonthlySpending * 1.1) {
      status = _PaceStatus.behindPace;
    } else {
      status = _PaceStatus.onTrack;
    }

    return _PaceData(
      daysInMonth: daysInMonth,
      dayOfMonth: dayOfMonth,
      isCurrentMonth: isCurrentMonth,
      timeProgress: timeProgress,
      spendingProgress: spendingProgress,
      projectedTotal: projectedTotal,
      amountLeftAtPace: amountLeftAtPace,
      status: status,
    );
  }
}

enum _PaceStatus {
  onTrack,
  aheadOfPace,
  behindPace,
}

class _PaceData {
  final int daysInMonth;
  final int dayOfMonth;
  final bool isCurrentMonth;
  final double timeProgress;
  final double spendingProgress;
  final double projectedTotal;
  final double amountLeftAtPace;
  final _PaceStatus status;

  const _PaceData({
    required this.daysInMonth,
    required this.dayOfMonth,
    required this.isCurrentMonth,
    required this.timeProgress,
    required this.spendingProgress,
    required this.projectedTotal,
    required this.amountLeftAtPace,
    required this.status,
  });
}
