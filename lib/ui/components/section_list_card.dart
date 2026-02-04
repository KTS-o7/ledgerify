import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';

class SectionListCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onHeaderTap;
  final List<Widget> children;
  final EdgeInsetsGeometry headerPadding;

  const SectionListCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.onHeaderTap,
    this.headerPadding = const EdgeInsets.all(LedgerifySpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onHeaderTap,
              borderRadius: LedgerifyRadius.borderRadiusMd,
              child: Padding(
                padding: headerPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: LedgerifyTypography.headlineSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
          if (children.isNotEmpty)
            const Divider(height: 1)
          else
            const SizedBox.shrink(),
          ...children.asMap().entries.expand((entry) sync* {
            final index = entry.key;
            final child = entry.value;
            yield child;
            if (index != children.length - 1) {
              yield const Divider(height: 1);
            }
          }),
        ],
      ),
    );
  }
}

