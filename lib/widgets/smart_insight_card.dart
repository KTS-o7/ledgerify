import 'package:flutter/material.dart';

import '../models/smart_insight.dart';
import '../theme/ledgerify_theme.dart';

/// A card widget that displays a single SmartInsight.
///
/// Follows Quiet Finance design principles:
/// - Factual, minimal presentation
/// - Color-coded by insight type
/// - Tappable for drill-down navigation
/// - Optional swipe-to-dismiss
class SmartInsightCard extends StatelessWidget {
  /// The insight to display.
  final SmartInsight insight;

  /// Callback when the card is tapped for drill-down.
  final VoidCallback? onTap;

  /// Callback when the card is dismissed via swipe.
  /// If null, swipe-to-dismiss is disabled.
  final VoidCallback? onDismiss;

  const SmartInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    Widget card = Material(
      color: colors.surfaceHighlight,
      borderRadius: LedgerifyRadius.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: LedgerifyRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.md,
          ),
          child: _buildContent(colors),
        ),
      ),
    );

    // Wrap in Dismissible if onDismiss is provided
    if (onDismiss != null) {
      card = Dismissible(
        key: Key(insight.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.negativeMuted,
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          child: Icon(
            Icons.close_rounded,
            color: colors.negative,
            size: 20,
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  Widget _buildContent(LedgerifyColorScheme colors) {
    final iconColor = _getIconColor(colors);

    return Row(
      children: [
        // Icon
        Icon(
          insight.icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: LedgerifySpacing.md),

        // Title + Description
        Expanded(
          child: _buildText(colors),
        ),

        const SizedBox(width: LedgerifySpacing.sm),

        // Chevron indicator
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: colors.textTertiary,
        ),
      ],
    );
  }

  Widget _buildText(LedgerifyColorScheme colors) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          // Title (semi-bold)
          TextSpan(
            text: insight.title,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Em-dash separator
          TextSpan(
            text: ' — ',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          // Description (regular)
          TextSpan(
            text: insight.description,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the appropriate icon color based on insight type.
  Color _getIconColor(LedgerifyColorScheme colors) {
    switch (insight.type) {
      case InsightType.anomaly:
        return colors.warning;
      case InsightType.warning:
        return colors.negative;
      case InsightType.comparison:
        return colors.textPrimary;
      case InsightType.achievement:
        return colors.accent;
      case InsightType.pattern:
        return colors.textSecondary;
    }
  }
}

/// A widget that displays a list of SmartInsight cards.
///
/// Shows a maximum of 3 insights. If the list is empty,
/// nothing is rendered (no "empty state" message).
class SmartInsightsList extends StatelessWidget {
  /// The list of insights to display.
  final List<SmartInsight> insights;

  /// Callback when an insight is tapped.
  final Function(SmartInsight)? onInsightTap;

  /// Callback when an insight is dismissed.
  final Function(SmartInsight)? onInsightDismiss;

  /// Maximum number of insights to display.
  static const int _maxInsights = 3;

  const SmartInsightsList({
    super.key,
    required this.insights,
    this.onInsightTap,
    this.onInsightDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty widget if no insights
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to max insights
    final displayedInsights = insights.take(_maxInsights).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayedInsights.length; i++) ...[
          SmartInsightCard(
            insight: displayedInsights[i],
            onTap: onInsightTap != null
                ? () => onInsightTap!(displayedInsights[i])
                : null,
            onDismiss: onInsightDismiss != null
                ? () => onInsightDismiss!(displayedInsights[i])
                : null,
          ),
          if (i < displayedInsights.length - 1)
            const SizedBox(height: LedgerifySpacing.sm),
        ],
      ],
    );
  }
}
