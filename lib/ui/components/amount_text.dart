import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';
import '../../utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final color = colors.amountColor(amount);
    final value = CurrencyFormatter.format(amount.abs());

    return Text(
      value,
      style: (style ?? LedgerifyTypography.amountMedium).copyWith(color: color),
    );
  }
}
