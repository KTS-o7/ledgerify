import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';

/// Weekday Selector Widget - Ledgerify Design Language
///
/// A row of circular toggles for selecting days of the week.
/// Used for weekly recurring expenses with specific days.
///
/// Days are numbered 1-7 where Monday=1 and Sunday=7 (ISO standard).
class WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat on',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: LedgerifySpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1; // 1-7
            final isSelected = selectedDays.contains(day);

            return Semantics(
              label:
                  '${_dayNames[index]}, ${isSelected ? 'selected' : 'not selected'}',
              button: true,
              child: GestureDetector(
                onTap: () => _toggleDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent : colors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[index],
                      style: LedgerifyTypography.labelMedium.copyWith(
                        color: isSelected
                            ? colors.background
                            : colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (selectedDays.isNotEmpty) ...[
          SizedBox(height: LedgerifySpacing.sm),
          Text(
            _buildSelectionDescription(),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  /// Toggles a day on or off.
  void _toggleDay(int day) {
    final newSelection = List<int>.from(selectedDays);

    if (newSelection.contains(day)) {
      newSelection.remove(day);
    } else {
      newSelection.add(day);
      newSelection.sort();
    }

    onChanged(newSelection);
  }

  /// Builds a human-readable description of selected days.
  String _buildSelectionDescription() {
    if (selectedDays.isEmpty) {
      return 'Select at least one day';
    }

    if (selectedDays.length == 7) {
      return 'Every day';
    }

    if (_isWeekdays()) {
      return 'Weekdays';
    }

    if (_isWeekends()) {
      return 'Weekends';
    }

    final dayNames = selectedDays.map((d) => _dayNames[d - 1]).toList();

    if (dayNames.length == 1) {
      return 'Every ${dayNames[0]}';
    }

    if (dayNames.length == 2) {
      return 'Every ${dayNames[0]} and ${dayNames[1]}';
    }

    final last = dayNames.removeLast();
    return 'Every ${dayNames.join(', ')} and $last';
  }

  /// Checks if selected days are exactly weekdays (Mon-Fri).
  bool _isWeekdays() {
    if (selectedDays.length != 5) return false;
    return selectedDays.every((d) => d >= 1 && d <= 5);
  }

  /// Checks if selected days are exactly weekends (Sat-Sun).
  bool _isWeekends() {
    if (selectedDays.length != 2) return false;
    return selectedDays.contains(6) && selectedDays.contains(7);
  }
}
