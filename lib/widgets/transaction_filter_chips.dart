import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';

/// Filter options for transaction lists
enum TransactionFilter {
  all,
  income,
  expenses;

  /// Display label for the filter
  String get label {
    switch (this) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.expenses:
        return 'Expenses';
    }
  }
}

/// A row of filter chips to switch between All/Income/Expenses views.
///
/// Follows Quiet Finance design philosophy with subtle animations
/// and calm visual feedback.
class TransactionFilterChips extends StatelessWidget {
  const TransactionFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  /// The currently selected filter
  final TransactionFilter selectedFilter;

  /// Callback when a filter is selected
  final ValueChanged<TransactionFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Row(
      children: TransactionFilter.values.map((filter) {
        final isSelected = filter == selectedFilter;
        return Padding(
          padding: EdgeInsets.only(
            right: filter != TransactionFilter.values.last
                ? LedgerifySpacing.sm
                : 0,
          ),
          child: _FilterChip(
            label: filter.label,
            isSelected: isSelected,
            colors: colors,
            onTap: () => onFilterChanged(filter),
          ),
        );
      }).toList(),
    );
  }
}

/// Individual filter chip with animated selection state
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final LedgerifyColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          style: LedgerifyTypography.labelMedium.copyWith(
            color: isSelected ? colors.background : colors.textSecondary,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
