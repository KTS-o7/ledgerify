import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(LedgerifySpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: LedgerifyTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              LedgerifySpacing.verticalMd,
            ],
            child,
          ],
        ),
      ),
    );
  }
}

