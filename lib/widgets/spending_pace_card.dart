import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';

/// Spending Pace One-Liner - Ledgerify Design Language
///
/// A minimal one-line indicator showing spending pace status with context.
/// Displays text like: "On track with your average" or "Spending 23% faster than usual"
///
/// For detailed pace analysis, see the Analytics tab's SpendingPaceIndicator.
///
/// Color coding:
/// - Green (accent) for "on track" or "slower"
/// - Orange (warning) for "slightly faster" (10-25%)
/// - Red (negative) for "much faster" (>25%)
class SpendingPaceOneLiner extends StatelessWidget {
  /// The spending pace data to display
  final SpendingPace pace;

  const SpendingPaceOneLiner({
    super.key,
    required this.pace,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getStatusIcon(),
          size: 14,
          color: _getStatusColor(colors),
        ),
        LedgerifySpacing.horizontalXs,
        Flexible(
          child: Text(
            _getStatusText(),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Gets the appropriate icon for the status
  IconData _getStatusIcon() {
    switch (pace.status) {
      case SpendingPaceStatus.onTrack:
        return Icons.check_circle_outline_rounded;
      case SpendingPaceStatus.faster:
        return Icons.trending_up_rounded;
      case SpendingPaceStatus.slower:
        return Icons.trending_down_rounded;
    }
  }

  /// Gets the appropriate color for the status
  Color _getStatusColor(LedgerifyColorScheme colors) {
    switch (pace.status) {
      case SpendingPaceStatus.onTrack:
        return colors.accent;
      case SpendingPaceStatus.slower:
        return colors.accent;
      case SpendingPaceStatus.faster:
        // Slightly faster (10-25%) = warning
        // Much faster (>25%) = negative
        if (pace.percentageDiff > 25) {
          return colors.negative;
        }
        return colors.warning;
    }
  }

  /// Gets the contextual status text
  String _getStatusText() {
    final percentage = pace.percentageDiff.abs().round();
    final avgLabel = pace.monthsInAverage == 1
        ? 'last month'
        : '${pace.monthsInAverage}-month average';

    switch (pace.status) {
      case SpendingPaceStatus.onTrack:
        return 'On track with your $avgLabel';
      case SpendingPaceStatus.faster:
        return 'Spending $percentage% faster than your $avgLabel';
      case SpendingPaceStatus.slower:
        return 'Spending $percentage% slower than your $avgLabel';
    }
  }
}
