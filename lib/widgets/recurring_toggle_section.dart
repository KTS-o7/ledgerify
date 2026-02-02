import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_expense.dart';
import '../theme/ledgerify_theme.dart';
import 'weekday_selector.dart';

/// Data class representing recurring settings for a transaction.
class RecurringSettings {
  final RecurrenceFrequency frequency;
  final int? dayOfMonth; // For monthly: 1-31, or 32 for "last day"
  final List<int>? weekdays; // For weekly: 1=Mon, 7=Sun
  final DateTime? endDate; // null = never

  const RecurringSettings({
    required this.frequency,
    this.dayOfMonth,
    this.weekdays,
    this.endDate,
  });

  RecurringSettings copyWith({
    RecurrenceFrequency? frequency,
    int? dayOfMonth,
    List<int>? weekdays,
    DateTime? endDate,
    bool clearDayOfMonth = false,
    bool clearWeekdays = false,
    bool clearEndDate = false,
  }) {
    return RecurringSettings(
      frequency: frequency ?? this.frequency,
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
      weekdays: clearWeekdays ? null : (weekdays ?? this.weekdays),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  @override
  String toString() {
    return 'RecurringSettings(frequency: $frequency, dayOfMonth: $dayOfMonth, '
        'weekdays: $weekdays, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecurringSettings) return false;
    return frequency == other.frequency &&
        dayOfMonth == other.dayOfMonth &&
        _listEquals(weekdays, other.weekdays) &&
        endDate == other.endDate;
  }

  @override
  int get hashCode => Object.hash(frequency, dayOfMonth, weekdays, endDate);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Enum for quick selection options in the recurring toggle.
enum RecurringOption {
  never,
  monthly,
  weekly,
  custom,
}

/// RecurringToggleSection Widget - Ledgerify Design Language
///
/// Allows users to mark a transaction as recurring without navigating
/// to a separate screen. Shows quick options (Never, Monthly, Weekly)
/// and a Custom option that expands to show full configuration.
///
/// Follows "Quiet Finance" design: calm, professional, no gamification.
class RecurringToggleSection extends StatefulWidget {
  /// Whether recurring is enabled (controlled mode indicator).
  final bool isEnabled;

  /// Callback when recurring settings change.
  /// Returns null when "Never" is selected, otherwise returns settings.
  final ValueChanged<RecurringSettings?> onChanged;

  /// The date of the transaction (for smart suggestions).
  final DateTime transactionDate;

  /// Optional title for smart detection (e.g., "Netflix" suggests monthly).
  final String? title;

  /// Whether this is for expense (true) or income (false).
  final bool isExpense;

  const RecurringToggleSection({
    super.key,
    required this.isEnabled,
    required this.onChanged,
    required this.transactionDate,
    this.title,
    this.isExpense = true,
  });

  @override
  State<RecurringToggleSection> createState() => _RecurringToggleSectionState();
}

class _RecurringToggleSectionState extends State<RecurringToggleSection>
    with SingleTickerProviderStateMixin {
  static const _monthlyPatterns = [
    'salary',
    'rent',
    'mortgage',
    'netflix',
    'spotify',
    'hulu',
    'disney',
    'prime',
    'subscription',
    'membership',
    'insurance',
    'premium',
    'emi',
    'loan',
    'phone bill',
    'internet',
    'electricity',
    'gas bill',
    'water bill',
  ];

  static const _weeklyPatterns = [
    'groceries',
    'grocery',
    'fuel',
    'petrol',
    'gas',
    'maid',
    'cleaning',
    'helper',
  ];

  static final _weekdayFormat = DateFormat('EEEE');

  late RecurringOption _selectedOption;
  late RecurrenceFrequency _customFrequency;
  late int _dayOfMonth;
  late List<int> _weekdays;
  DateTime? _endDate;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize day of month from transaction date
    _dayOfMonth = widget.transactionDate.day;

    // Initialize weekday from transaction date (DateTime uses 1=Mon, 7=Sun)
    _weekdays = [widget.transactionDate.weekday];

    // Default custom frequency
    _customFrequency = RecurrenceFrequency.monthly;

    // Check for smart suggestion and set initial option
    final suggestion = _suggestFrequency(widget.title);
    if (suggestion != null && widget.isEnabled) {
      _selectedOption = suggestion == RecurrenceFrequency.monthly
          ? RecurringOption.monthly
          : RecurringOption.weekly;
    } else {
      _selectedOption =
          widget.isEnabled ? RecurringOption.monthly : RecurringOption.never;
    }

    // Animation for custom section expansion
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RecurringToggleSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update day of month if transaction date changed
    if (oldWidget.transactionDate.day != widget.transactionDate.day) {
      _dayOfMonth = widget.transactionDate.day;
    }

    // Update weekday if transaction date changed
    if (oldWidget.transactionDate.weekday != widget.transactionDate.weekday) {
      _weekdays = [widget.transactionDate.weekday];
    }

    // Handle smart suggestion changes
    if (oldWidget.title != widget.title) {
      final suggestion = _suggestFrequency(widget.title);
      if (suggestion != null && _selectedOption == RecurringOption.never) {
        setState(() {
          _selectedOption = suggestion == RecurrenceFrequency.monthly
              ? RecurringOption.monthly
              : RecurringOption.weekly;
        });
        _notifyChange();
      }
    }
  }

  /// Suggests a frequency based on the transaction title.
  RecurrenceFrequency? _suggestFrequency(String? title) {
    if (title == null || title.isEmpty) return null;
    final lower = title.toLowerCase();

    // Monthly patterns - subscriptions, bills, regular payments
    if (_monthlyPatterns.any((p) => lower.contains(p))) {
      return RecurrenceFrequency.monthly;
    }

    // Weekly patterns
    if (_weeklyPatterns.any((p) => lower.contains(p))) {
      return RecurrenceFrequency.weekly;
    }

    return null;
  }

  void _selectOption(RecurringOption option) {
    setState(() {
      _selectedOption = option;
      if (option == RecurringOption.custom) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    switch (_selectedOption) {
      case RecurringOption.never:
        widget.onChanged(null);
        break;
      case RecurringOption.monthly:
        widget.onChanged(RecurringSettings(
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: _dayOfMonth,
          endDate: _endDate,
        ));
        break;
      case RecurringOption.weekly:
        widget.onChanged(RecurringSettings(
          frequency: RecurrenceFrequency.weekly,
          weekdays: List.from(_weekdays),
          endDate: _endDate,
        ));
        break;
      case RecurringOption.custom:
        widget.onChanged(RecurringSettings(
          frequency: _customFrequency,
          dayOfMonth: _customFrequency == RecurrenceFrequency.monthly ||
                  _customFrequency == RecurrenceFrequency.yearly
              ? _dayOfMonth
              : null,
          weekdays: _customFrequency == RecurrenceFrequency.weekly
              ? List.from(_weekdays)
              : null,
          endDate: _endDate,
        ));
        break;
    }
  }

  String _getMonthlyLabel() {
    final day = widget.transactionDate.day;
    return 'Monthly on ${_ordinal(day)}';
  }

  String _getWeeklyLabel() {
    final dayName = _weekdayFormat.format(widget.transactionDate);
    return 'Weekly on ${dayName}s';
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(colors),
          LedgerifySpacing.verticalMd,

          // Quick options
          _buildOption(colors, RecurringOption.never, 'Never'),
          LedgerifySpacing.verticalSm,
          _buildOption(colors, RecurringOption.monthly, _getMonthlyLabel()),
          LedgerifySpacing.verticalSm,
          _buildOption(colors, RecurringOption.weekly, _getWeeklyLabel()),
          LedgerifySpacing.verticalSm,
          _buildOption(colors, RecurringOption.custom, 'Custom...'),

          // Expandable custom section
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1,
            child: _buildCustomSection(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Row(
      children: [
        Icon(
          Icons.repeat_rounded,
          size: 20,
          color: colors.textSecondary,
        ),
        LedgerifySpacing.horizontalSm,
        Text(
          'Repeat',
          style: LedgerifyTypography.labelLarge.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    LedgerifyColorScheme colors,
    RecurringOption option,
    String label,
  ) {
    final isSelected = _selectedOption == option;

    return GestureDetector(
      onTap: () => _selectOption(option),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.xs),
        child: Row(
          children: [
            // Custom radio button
            _buildRadio(colors, isSelected),
            LedgerifySpacing.horizontalMd,
            Expanded(
              child: Text(
                label,
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(LedgerifyColorScheme colors, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.accent : colors.textTertiary,
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCustomSection(LedgerifyColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: LedgerifySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency picker
          _buildFrequencyDropdown(colors),
          LedgerifySpacing.verticalMd,

          // Day picker (depends on frequency)
          if (_customFrequency == RecurrenceFrequency.weekly)
            WeekdaySelector(
              selectedDays: _weekdays,
              onChanged: (days) {
                setState(() => _weekdays = days);
                _notifyChange();
              },
            )
          else if (_customFrequency == RecurrenceFrequency.monthly ||
              _customFrequency == RecurrenceFrequency.yearly)
            _buildDayOfMonthPicker(colors),

          LedgerifySpacing.verticalMd,

          // End date picker
          _buildEndDatePicker(colors),
        ],
      ),
    );
  }

  Widget _buildFrequencyDropdown(LedgerifyColorScheme colors) {
    // Exclude 'custom' from frequencies shown
    final frequencies = RecurrenceFrequency.values
        .where((f) => f != RecurrenceFrequency.custom)
        .toList();

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
        GestureDetector(
          onTap: () => _showFrequencySheet(colors, frequencies),
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
                  _customFrequency.icon,
                  size: 20,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Text(
                    _customFrequency.displayName,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
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

  void _showFrequencySheet(
    LedgerifyColorScheme colors,
    List<RecurrenceFrequency> frequencies,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) {
        final sheetColors = LedgerifyColors.of(context);
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
                  color: sheetColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                child: Text(
                  'Select Frequency',
                  style: LedgerifyTypography.headlineSmall.copyWith(
                    color: sheetColors.textPrimary,
                  ),
                ),
              ),
              ...frequencies.map((freq) {
                final isSelected = freq == _customFrequency;
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _customFrequency = freq);
                    _notifyChange();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.lg,
                      vertical: LedgerifySpacing.md,
                    ),
                    color: isSelected
                        ? sheetColors.accentMuted
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          freq.icon,
                          size: 24,
                          color: isSelected
                              ? sheetColors.accent
                              : sheetColors.textSecondary,
                        ),
                        LedgerifySpacing.horizontalMd,
                        Expanded(
                          child: Text(
                            freq.displayName,
                            style: LedgerifyTypography.bodyLarge.copyWith(
                              color: isSelected
                                  ? sheetColors.accent
                                  : sheetColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            color: sheetColors.accent,
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
      },
    );
  }

  Widget _buildDayOfMonthPicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GestureDetector(
          onTap: () => _showDayOfMonthSheet(colors),
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
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Text(
                    _dayOfMonth == 32 ? 'Last day' : _ordinal(_dayOfMonth),
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
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

  void _showDayOfMonthSheet(LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) {
        final sheetColors = LedgerifyColors.of(context);
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
                  color: sheetColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                child: Text(
                  'Select Day',
                  style: LedgerifyTypography.headlineSmall.copyWith(
                    color: sheetColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: LedgerifySpacing.sm,
                    crossAxisSpacing: LedgerifySpacing.sm,
                  ),
                  itemCount: 32, // 1-31 + "Last day"
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = _dayOfMonth == day;
                    final isLastDay = day == 32;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _dayOfMonth = day);
                        _notifyChange();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? sheetColors.accent
                              : sheetColors.surfaceHighlight,
                          borderRadius: LedgerifyRadius.borderRadiusSm,
                        ),
                        child: Center(
                          child: Text(
                            isLastDay ? 'L' : '$day',
                            style: LedgerifyTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? sheetColors.background
                                  : sheetColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                ),
                child: Text(
                  'L = Last day of month',
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: sheetColors.textTertiary,
                  ),
                ),
              ),
              LedgerifySpacing.verticalLg,
            ],
          ),
        );
      },
    );
  }

  Widget _buildEndDatePicker(LedgerifyColorScheme colors) {
    final hasEndDate = _endDate != null;
    final displayText =
        hasEndDate ? DateFormat('d MMM yyyy').format(_endDate!) : 'Never';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ends',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GestureDetector(
          onTap: () => _showEndDateSheet(colors),
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
                  hasEndDate
                      ? Icons.event_rounded
                      : Icons.all_inclusive_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: Text(
                    displayText,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (hasEndDate)
                  GestureDetector(
                    onTap: () {
                      setState(() => _endDate = null);
                      _notifyChange();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  )
                else
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

  void _showEndDateSheet(LedgerifyColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) {
        final sheetColors = LedgerifyColors.of(context);
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
                  color: sheetColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                child: Text(
                  'Ends',
                  style: LedgerifyTypography.headlineSmall.copyWith(
                    color: sheetColors.textPrimary,
                  ),
                ),
              ),
              // Never option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _endDate = null);
                  _notifyChange();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                    vertical: LedgerifySpacing.md,
                  ),
                  color: _endDate == null
                      ? sheetColors.accentMuted
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 24,
                        color: _endDate == null
                            ? sheetColors.accent
                            : sheetColors.textSecondary,
                      ),
                      LedgerifySpacing.horizontalMd,
                      Expanded(
                        child: Text(
                          'Never',
                          style: LedgerifyTypography.bodyLarge.copyWith(
                            color: _endDate == null
                                ? sheetColors.accent
                                : sheetColors.textPrimary,
                            fontWeight: _endDate == null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (_endDate == null)
                        Icon(
                          Icons.check_rounded,
                          color: sheetColors.accent,
                        ),
                    ],
                  ),
                ),
              ),
              // Pick a date option
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: sheetColors.accent,
                                surface: sheetColors.surface,
                              ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                    _notifyChange();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                    vertical: LedgerifySpacing.md,
                  ),
                  color: _endDate != null
                      ? sheetColors.accentMuted
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 24,
                        color: _endDate != null
                            ? sheetColors.accent
                            : sheetColors.textSecondary,
                      ),
                      LedgerifySpacing.horizontalMd,
                      Expanded(
                        child: Text(
                          _endDate != null
                              ? DateFormat('d MMM yyyy').format(_endDate!)
                              : 'Pick a date',
                          style: LedgerifyTypography.bodyLarge.copyWith(
                            color: _endDate != null
                                ? sheetColors.accent
                                : sheetColors.textPrimary,
                            fontWeight: _endDate != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (_endDate != null)
                        Icon(
                          Icons.check_rounded,
                          color: sheetColors.accent,
                        ),
                    ],
                  ),
                ),
              ),
              LedgerifySpacing.verticalLg,
            ],
          ),
        );
      },
    );
  }
}
