import 'package:flutter/material.dart';
import '../models/recurring_expense.dart';
import '../theme/ledgerify_theme.dart';

/// Frequency Picker Widget - Ledgerify Design Language
///
/// A dropdown-style picker for selecting recurrence frequency.
/// Shows icon, name, and description for each frequency option.
class FrequencyPicker extends StatelessWidget {
  final RecurrenceFrequency value;
  final ValueChanged<RecurrenceFrequency> onChanged;

  const FrequencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        InkWell(
          onTap: () => _showFrequencyPicker(context, colors),
          borderRadius: LedgerifyRadius.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  value.icon,
                  size: 24,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.displayName,
                        style: LedgerifyTypography.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        value.description,
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a bottom sheet with frequency options.
  void _showFrequencyPicker(BuildContext context, LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) => _FrequencyPickerSheet(
        currentValue: value,
        onSelected: (frequency) {
          Navigator.pop(context);
          onChanged(frequency);
        },
      ),
    );
  }
}

/// Bottom sheet content for frequency selection.
class _FrequencyPickerSheet extends StatelessWidget {
  final RecurrenceFrequency currentValue;
  final ValueChanged<RecurrenceFrequency> onSelected;

  const _FrequencyPickerSheet({
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: LedgerifySpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            child: Text(
              'Select Frequency',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),

          // Options
          ...RecurrenceFrequency.values.map((frequency) {
            final isSelected = frequency == currentValue;

            return InkWell(
              onTap: () => onSelected(frequency),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                  vertical: LedgerifySpacing.md,
                ),
                color: isSelected ? colors.accentMuted : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      frequency.icon,
                      size: 24,
                      color: isSelected ? colors.accent : colors.textSecondary,
                    ),
                    LedgerifySpacing.horizontalMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            frequency.displayName,
                            style: LedgerifyTypography.bodyLarge.copyWith(
                              color: isSelected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          Text(
                            frequency.description,
                            style: LedgerifyTypography.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        color: colors.accent,
                      ),
                  ],
                ),
              ),
            );
          }),

          LedgerifySpacing.verticalLg,
        ],
      ),
    );
  }
}
