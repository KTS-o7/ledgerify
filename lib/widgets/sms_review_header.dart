import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// SMS Review Header - Ledgerify Design Language
///
/// Displays summary card showing pending count, total debit/credit amounts.
/// Used at the top of the SMS review screen.
class SmsReviewHeader extends StatelessWidget {
  final int pendingCount;
  final int debitCount;
  final int creditCount;
  final double totalDebitAmount;
  final double totalCreditAmount;

  const SmsReviewHeader({
    super.key,
    required this.pendingCount,
    required this.debitCount,
    required this.creditCount,
    required this.totalDebitAmount,
    required this.totalCreditAmount,
  });

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
          // Title
          Text(
            _getPendingText(),
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),

          LedgerifySpacing.verticalLg,

          // Debit and Credit summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  colors: colors,
                  label: 'DEBITS',
                  count: debitCount,
                  amount: totalDebitAmount,
                  amountColor: colors.negative,
                ),
              ),
              LedgerifySpacing.horizontalMd,
              Expanded(
                child: _buildSummaryTile(
                  colors: colors,
                  label: 'CREDITS',
                  count: creditCount,
                  amount: totalCreditAmount,
                  amountColor: colors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required LedgerifyColorScheme colors,
    required String label,
    required int count,
    required double amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: LedgerifyTypography.labelSmall.copyWith(
              color: colors.textTertiary,
            ),
          ),

          LedgerifySpacing.verticalXs,

          // Count
          Text(
            count.toString(),
            style: LedgerifyTypography.headlineSmall.copyWith(
              color: colors.textPrimary,
            ),
          ),

          LedgerifySpacing.verticalXs,

          // Amount
          Text(
            CurrencyFormatter.format(amount),
            style: LedgerifyTypography.amountMedium.copyWith(
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getPendingText() {
    if (pendingCount == 0) return 'No transactions to review';
    if (pendingCount == 1) return '1 transaction to review';
    return '$pendingCount transactions to review';
  }
}
