import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sms_transaction.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../parsers/category_classifier.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// SMS Review Tile - Ledgerify Design Language
///
/// Displays an individual SMS transaction with action buttons for review.
/// Features:
/// - Type badge (debit/credit)
/// - Amount with confidence indicator
/// - Merchant and account info
/// - Editable category/source
/// - Confirm, Edit, Skip action buttons
/// - Swipe gestures for quick actions
class SmsReviewTile extends StatelessWidget {
  final SmsTransaction transaction;
  final ExpenseCategory? categoryOverride;
  final IncomeSource? sourceOverride;
  final bool isProcessing;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;
  final VoidCallback onEditCategory;
  final VoidCallback onEditSource;

  const SmsReviewTile({
    super.key,
    required this.transaction,
    this.categoryOverride,
    this.sourceOverride,
    required this.isProcessing,
    required this.onConfirm,
    required this.onSkip,
    required this.onEditCategory,
    required this.onEditSource,
  });

  /// Date formatter for "MMM d, yyyy" format
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  /// Get the category to display (override or auto-classified)
  ExpenseCategory get _displayCategory {
    if (categoryOverride != null) return categoryOverride!;
    return CategoryClassifier.classify(transaction.merchant);
  }

  /// Get the source to display (override or default)
  IncomeSource get _displaySource {
    return sourceOverride ?? IncomeSource.other;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(transaction.smsId),
        background: _buildSwipeBackground(
          colors: colors,
          alignment: Alignment.centerLeft,
          icon: Icons.check_rounded,
          color: colors.accent,
          label: 'Confirm',
        ),
        secondaryBackground: _buildSwipeBackground(
          colors: colors,
          alignment: Alignment.centerRight,
          icon: Icons.close_rounded,
          color: colors.textTertiary,
          label: 'Skip',
        ),
        confirmDismiss: (direction) async {
          if (isProcessing) return false;
          if (direction == DismissDirection.startToEnd) {
            onConfirm();
          } else {
            onSkip();
          }
          return false;
        },
        child: Container(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors),
              LedgerifySpacing.verticalSm,
              _buildMerchantRow(colors),
              LedgerifySpacing.verticalXs,
              _buildAccountRow(colors),
              LedgerifySpacing.verticalMd,
              _buildCategorySourceRow(colors),
              LedgerifySpacing.verticalMd,
              _buildActionButtons(colors),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the swipe background for Dismissible
  Widget _buildSwipeBackground({
    required LedgerifyColorScheme colors,
    required AlignmentGeometry alignment,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: color, size: 24),
                LedgerifySpacing.horizontalSm,
                Text(
                  label,
                  style: LedgerifyTypography.labelLarge.copyWith(color: color),
                ),
              ]
            : [
                Text(
                  label,
                  style: LedgerifyTypography.labelLarge.copyWith(color: color),
                ),
                LedgerifySpacing.horizontalSm,
                Icon(icon, color: color, size: 24),
              ],
      ),
    );
  }

  /// Builds the header row with type badge, amount, and confidence
  Widget _buildHeader(LedgerifyColorScheme colors) {
    final isDebit = transaction.isDebit;
    final badgeColor = isDebit ? colors.negative : colors.accent;
    final badgeText = isDebit ? 'DEBIT' : 'CREDIT';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.sm,
            vertical: LedgerifySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: LedgerifyRadius.borderRadiusSm,
          ),
          child: Text(
            badgeText,
            style: LedgerifyTypography.labelSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        LedgerifySpacing.horizontalMd,
        // Amount
        Text(
          CurrencyFormatter.format(transaction.amount),
          style: LedgerifyTypography.amountLarge.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const Spacer(),
        // Confidence indicator
        _buildConfidenceIndicator(colors),
      ],
    );
  }

  /// Builds the confidence indicator dot with tooltip
  Widget _buildConfidenceIndicator(LedgerifyColorScheme colors) {
    final confidence = transaction.confidence;
    final Color dotColor;
    final String tooltip;
    final bool isFilled;

    if (confidence > 0.8) {
      dotColor = colors.accent;
      tooltip = 'High confidence';
      isFilled = true;
    } else if (confidence >= 0.5) {
      dotColor = Colors.orange;
      tooltip = 'Medium confidence';
      isFilled = true;
    } else {
      dotColor = colors.textTertiary;
      tooltip = 'Low confidence';
      isFilled = false;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? dotColor : Colors.transparent,
              border: isFilled ? null : Border.all(color: dotColor, width: 1.5),
            ),
          ),
          LedgerifySpacing.horizontalXs,
          Text(
            '${(confidence * 100).round()}%',
            style: LedgerifyTypography.labelSmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the merchant/description row
  Widget _buildMerchantRow(LedgerifyColorScheme colors) {
    final merchant = transaction.merchant ?? 'Unknown';
    final date = _dateFormat.format(transaction.smsDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            merchant,
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        LedgerifySpacing.horizontalMd,
        Text(
          date,
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Builds the account number row
  Widget _buildAccountRow(LedgerifyColorScheme colors) {
    if (transaction.accountNumber == null) return const SizedBox.shrink();

    return Text(
      'A/c \u2022\u2022\u2022\u2022 ${transaction.accountNumber}',
      style: LedgerifyTypography.bodySmall.copyWith(
        color: colors.textTertiary,
      ),
    );
  }

  /// Builds the editable category/source row
  Widget _buildCategorySourceRow(LedgerifyColorScheme colors) {
    final isDebit = transaction.isDebit;

    return InkWell(
      onTap: isDebit ? onEditCategory : onEditSource,
      borderRadius: LedgerifyRadius.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDebit ? _displayCategory.icon : _displaySource.icon,
              size: 18,
              color: colors.textSecondary,
            ),
            LedgerifySpacing.horizontalSm,
            Text(
              isDebit
                  ? 'Category: ${_displayCategory.displayName}'
                  : 'Source: ${_displaySource.displayName}',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.horizontalXs,
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons row
  Widget _buildActionButtons(LedgerifyColorScheme colors) {
    if (isProcessing) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      );
    }

    return Row(
      children: [
        _buildActionButton(
          colors: colors,
          icon: Icons.check_rounded,
          label: 'Confirm',
          color: colors.accent,
          onTap: onConfirm,
        ),
        LedgerifySpacing.horizontalSm,
        _buildActionButton(
          colors: colors,
          icon: Icons.edit_rounded,
          label: 'Edit',
          color: colors.textSecondary,
          onTap: transaction.isDebit ? onEditCategory : onEditSource,
        ),
        LedgerifySpacing.horizontalSm,
        _buildActionButton(
          colors: colors,
          icon: Icons.close_rounded,
          label: 'Skip',
          color: colors.textTertiary,
          onTap: onSkip,
        ),
      ],
    );
  }

  /// Builds an individual action button
  Widget _buildActionButton({
    required LedgerifyColorScheme colors,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: LedgerifyRadius.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              LedgerifySpacing.verticalXs,
              Text(
                label,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
