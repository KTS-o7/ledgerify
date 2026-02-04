import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../ui/components/amount_text.dart';
import '../ui/components/app_scaffold.dart';
import '../ui/components/empty_state.dart';
import '../ui/components/filter_chips_bar.dart';
import '../ui/components/metric_row.dart';
import '../ui/components/section_card.dart';

class UiGalleryScreen extends StatelessWidget {
  const UiGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return AppScaffold(
      title: 'UI Gallery',
      automaticallyImplyLeading: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        children: [
          const SectionCard(
            title: 'Metrics',
            child: MetricRow(
              left: MetricItem(
                label: 'Income',
                amount: 3200,
                icon: Icons.arrow_downward_rounded,
                showPlus: true,
              ),
              middle: MetricItem(
                label: 'Spend',
                amount: -1842.5,
                icon: Icons.arrow_upward_rounded,
              ),
              right: MetricItem(
                label: 'Net',
                amount: 1357.5,
                icon: Icons.savings_rounded,
              ),
            ),
          ),
          LedgerifySpacing.verticalLg,
          SectionCard(
            title: 'Amounts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AmountText(
                  amount: 123.45,
                  showPlusForIncome: true,
                ),
                LedgerifySpacing.verticalSm,
                const AmountText(amount: -67.89),
                LedgerifySpacing.verticalSm,
                Text(
                  'Token accent: ${colors.accent.toARGB32().toRadixString(16)}',
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          LedgerifySpacing.verticalLg,
          SectionCard(
            title: 'Filter Chips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example sticky chip row',
                  style: LedgerifyTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                LedgerifySpacing.verticalMd,
                ClipRRect(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  child: FilterChipsBar(
                    chips: [
                      FilterChip(
                        label: const Text('This month'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text('Food'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text('Tags'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LedgerifySpacing.verticalLg,
          SectionCard(
            title: 'Empty State',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: colors.surfaceHighlight,
                borderRadius: LedgerifyRadius.borderRadiusMd,
              ),
              child: const EmptyState(
                title: 'No transactions yet',
                subtitle: 'Add your first expense to start tracking.',
                ctaLabel: 'Add expense',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
