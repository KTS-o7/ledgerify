import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';

class FilterChipsBar extends StatelessWidget {
  final List<Widget> chips;

  const FilterChipsBar({
    super.key,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.lg),
        child: Row(
          children: [
            for (final chip in chips) ...[
              chip,
              LedgerifySpacing.horizontalSm,
            ],
          ],
        ),
      ),
    );
  }
}

