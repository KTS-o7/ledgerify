import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Quick date selection widget with chips for common dates.
///
/// Provides fast selection for "Today", "Yesterday", and "Pick date..."
/// which opens a full date picker dialog.
///
/// Design: Compact chips with clear selection state.
/// - Selected: accent background, dark text
/// - Unselected: surfaceHighlight background, secondary text
class QuickDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const QuickDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
  });

  /// Checks if the selected date is today.
  bool get _isToday {
    final now = DateTime.now();
    return _isSameDay(selectedDate, now);
  }

  /// Checks if the selected date is yesterday.
  bool get _isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(selectedDate, yesterday);
  }

  /// Checks if the selected date is neither today nor yesterday (custom date).
  bool get _isCustomDate => !_isToday && !_isYesterday;

  /// Compares two dates ignoring time.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Selects today's date.
  void _selectToday() {
    final today = DateTime.now();
    if (!_isToday) {
      onDateChanged(today);
    }
  }

  /// Selects yesterday's date.
  void _selectYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (!_isYesterday) {
      onDateChanged(yesterday);
    }
  }

  /// Opens the date picker dialog.
  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? now,
      helpText: 'Select expense date',
    );

    if (picked != null && !_isSameDay(picked, selectedDate)) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        // Chip row
        Row(
          children: [
            _buildChip(
              context: context,
              colors: colors,
              label: 'Today',
              isSelected: _isToday,
              onTap: _selectToday,
            ),
            LedgerifySpacing.horizontalSm,
            _buildChip(
              context: context,
              colors: colors,
              label: 'Yesterday',
              isSelected: _isYesterday,
              onTap: _selectYesterday,
            ),
            LedgerifySpacing.horizontalSm,
            _buildChip(
              context: context,
              colors: colors,
              label: 'Pick date...',
              isSelected: _isCustomDate,
              onTap: () => _openDatePicker(context),
            ),
          ],
        ),
        LedgerifySpacing.verticalSm,
        // Formatted date display
        Text(
          DateFormatter.format(selectedDate),
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required LedgerifyColorScheme colors,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.sm,
          vertical: LedgerifySpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusSm,
        ),
        child: Text(
          label,
          style: LedgerifyTypography.labelMedium.copyWith(
            color: isSelected ? colors.background : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
