import 'package:flutter/material.dart';
import '../models/income.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Income List Tile - Ledgerify Design Language
///
/// Displays a single income entry with:
/// - Source icon in colored circular background
/// - Description or source name
/// - Source type and date
/// - Amount with + prefix (accent color)
/// - Allocation summary if applicable
/// - Swipe to delete action
class IncomeListTile extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const IncomeListTile({
    super.key,
    required this.income,
    this.onTap,
    this.onDelete,
  });

  /// Returns the title to display.
  /// If description is set, show it. Otherwise show source displayName.
  String _getTitle() {
    if (income.description != null && income.description!.isNotEmpty) {
      return income.description!;
    }
    return income.source.displayName;
  }

  /// Returns the subtitle to display.
  /// Shows source type + date.
  String _getSubtitle() {
    final hasDescription =
        income.description != null && income.description!.isNotEmpty;

    final sourcePart = hasDescription ? income.source.displayName : '';
    final datePart = DateFormatter.format(income.date);

    if (sourcePart.isNotEmpty) {
      return '$sourcePart • $datePart';
    }
    return datePart;
  }

  /// Builds the allocation summary text.
  String _getAllocationSummary() {
    if (!income.hasAllocations) return '';

    if (income.goalAllocations.length == 1) {
      final allocation = income.goalAllocations.first;
      final percentage = allocation.percentage.toStringAsFixed(0);
      return '${CurrencyFormatter.format(allocation.amount)} ($percentage%)';
    }

    // Multiple allocations - show count
    return 'Allocated to ${income.goalAllocations.length} goals';
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    final title = _getTitle();
    final subtitle = _getSubtitle();
    final allocationSummary = _getAllocationSummary();

    final Widget content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accentMuted,
                borderRadius: LedgerifyRadius.borderRadiusMd,
              ),
              child: Icon(
                income.source.icon,
                size: 24,
                color: colors.accent,
              ),
            ),

            LedgerifySpacing.horizontalMd,

            // Title, subtitle, and allocations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LedgerifyTypography.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  if (income.hasAllocations) ...[
                    LedgerifySpacing.verticalXs,
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: colors.textTertiary,
                        ),
                        LedgerifySpacing.horizontalXs,
                        Expanded(
                          child: Text(
                            allocationSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LedgerifyTypography.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            LedgerifySpacing.horizontalMd,

            // Amount
            Text(
              '+ ${CurrencyFormatter.format(income.amount)}',
              style: LedgerifyTypography.amountMedium.copyWith(
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with Dismissible if onDelete is provided
    if (onDelete != null) {
      return RepaintBoundary(
        child: Dismissible(
          key: ValueKey(income.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: LedgerifySpacing.xl),
            color: colors.negative,
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (_) async {
            onDelete!();
            return false; // We handle deletion in the callback
          },
          child: content,
        ),
      );
    }

    return content;
  }
}
