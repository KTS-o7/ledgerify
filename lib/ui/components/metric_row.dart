import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';
import 'amount_text.dart';

class MetricRow extends StatelessWidget {
  final MetricItem left;
  final MetricItem middle;
  final MetricItem right;

  const MetricRow({
    super.key,
    required this.left,
    required this.middle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricTile(item: left)),
        LedgerifySpacing.horizontalSm,
        Expanded(child: _MetricTile(item: middle)),
        LedgerifySpacing.horizontalSm,
        Expanded(child: _MetricTile(item: right)),
      ],
    );
  }
}

class MetricItem {
  final String label;
  final double amount;
  final IconData icon;
  final bool showPlus;

  const MetricItem({
    required this.label,
    required this.amount,
    required this.icon,
    this.showPlus = false,
  });
}

class _MetricTile extends StatelessWidget {
  final MetricItem item;

  const _MetricTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 18, color: colors.textSecondary),
              LedgerifySpacing.horizontalSm,
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          LedgerifySpacing.verticalSm,
          AmountText(
            amount: item.amount,
            showPlusForIncome: item.showPlus,
            style: LedgerifyTypography.amountMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
