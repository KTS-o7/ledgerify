import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: LedgerifyTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                LedgerifySpacing.verticalSm,
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: LedgerifyTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (ctaLabel != null && onCtaTap != null) ...[
                LedgerifySpacing.verticalLg,
                FilledButton(
                  onPressed: onCtaTap,
                  child: Text(ctaLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

