import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final AlignmentGeometry alignment;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final color = colors.amountColor(amount);
    final value = CurrencyFormatter.format(amount.abs());

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        value,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style:
            (style ?? LedgerifyTypography.amountMedium).copyWith(color: color),
      ),
    );
  }
}
