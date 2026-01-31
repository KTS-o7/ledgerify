import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'expense.dart';

part 'recurring_expense.g.dart';

/// Enum representing how often a recurring expense repeats.
@HiveType(typeId: 3)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  yearly,

  @HiveField(4)
  custom,
}

/// Extension to provide display names and icons for frequencies.
extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.custom:
        return 'Custom';
    }
  }

  /// Returns a description for the frequency.
  String get description {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Every day';
      case RecurrenceFrequency.weekly:
        return 'Every week';
      case RecurrenceFrequency.monthly:
        return 'Every month';
      case RecurrenceFrequency.yearly:
        return 'Every year';
      case RecurrenceFrequency.custom:
        return 'Custom interval';
    }
  }

  /// Returns a Material icon for the frequency.
  IconData get icon {
    switch (this) {
      case RecurrenceFrequency.daily:
        return Icons.today_rounded;
      case RecurrenceFrequency.weekly:
        return Icons.view_week_rounded;
      case RecurrenceFrequency.monthly:
        return Icons.calendar_month_rounded;
      case RecurrenceFrequency.yearly:
        return Icons.event_rounded;
      case RecurrenceFrequency.custom:
        return Icons.tune_rounded;
    }
  }
}

/// Model representing a recurring expense template.
///
/// This defines a pattern for expenses that repeat on a schedule.
/// The system generates actual [Expense] entries based on this template.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [title]: Name of the recurring expense (e.g., "Netflix", "Rent")
/// - [amount]: The expense amount
/// - [category]: Category of the expense
/// - [frequency]: How often it repeats
/// - [customIntervalDays]: For custom frequency, the number of days between occurrences
/// - [weekdays]: For weekly frequency, specific days of week (1=Mon, 7=Sun)
/// - [dayOfMonth]: For monthly frequency, specific day (1-31, or 32 for last day)
/// - [startDate]: When the recurrence begins
/// - [endDate]: Optional end date for the recurrence
/// - [lastGeneratedDate]: The last date an expense was generated
/// - [nextDueDate]: The next date an expense should be generated
/// - [isActive]: Whether the recurring expense is active (can be paused)
/// - [note]: Optional note to include in generated expenses
/// - [createdAt]: When this recurring expense was created
@HiveType(typeId: 4)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final ExpenseCategory category;

  @HiveField(4)
  final RecurrenceFrequency frequency;

  @HiveField(5)
  final int customIntervalDays;

  @HiveField(6)
  final List<int>? weekdays;

  @HiveField(7)
  final int? dayOfMonth;

  @HiveField(8)
  final DateTime startDate;

  @HiveField(9)
  final DateTime? endDate;

  @HiveField(10)
  final DateTime? lastGeneratedDate;

  @HiveField(11)
  final DateTime nextDueDate;

  @HiveField(12)
  final bool isActive;

  @HiveField(13)
  final String? note;

  @HiveField(14)
  final DateTime createdAt;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    this.customIntervalDays = 1,
    this.weekdays,
    this.dayOfMonth,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    required this.nextDueDate,
    this.isActive = true,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this recurring expense with optional field overrides.
  RecurringExpense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    RecurrenceFrequency? frequency,
    int? customIntervalDays,
    List<int>? weekdays,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastGeneratedDate,
    DateTime? nextDueDate,
    bool? isActive,
    String? note,
    DateTime? createdAt,
    bool clearEndDate = false,
    bool clearLastGeneratedDate = false,
    bool clearWeekdays = false,
    bool clearDayOfMonth = false,
    bool clearNote = false,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      weekdays: clearWeekdays ? null : (weekdays ?? this.weekdays),
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGeneratedDate: clearLastGeneratedDate
          ? null
          : (lastGeneratedDate ?? this.lastGeneratedDate),
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns a human-readable description of the recurrence pattern.
  String get frequencyDescription {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        if (weekdays != null && weekdays!.isNotEmpty) {
          final dayNames = weekdays!.map(_weekdayName).join(', ');
          return 'Weekly on $dayNames';
        }
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        if (dayOfMonth != null) {
          if (dayOfMonth == 32) {
            return 'Monthly (last day)';
          }
          return 'Monthly on day $dayOfMonth';
        }
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.custom:
        if (customIntervalDays == 1) {
          return 'Every day';
        }
        return 'Every $customIntervalDays days';
    }
  }

  /// Converts weekday number (1-7) to short name.
  static String _weekdayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (day >= 1 && day <= 7) {
      return names[day - 1];
    }
    return '?';
  }

  /// Returns full weekday name.
  static String weekdayFullName(int day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (day >= 1 && day <= 7) {
      return names[day - 1];
    }
    return 'Unknown';
  }

  /// Checks if this recurring expense has ended.
  bool get hasEnded {
    if (endDate == null) return false;
    final now = DateTime.now();
    return endDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Checks if an expense is due for generation.
  bool get isDue {
    if (!isActive) return false;
    if (hasEnded) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );

    // Due if nextDueDate is today or in the past
    return !dueDate.isAfter(today);
  }

  /// Checks if already generated today.
  bool get alreadyGeneratedToday {
    if (lastGeneratedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastGen = DateTime(
      lastGeneratedDate!.year,
      lastGeneratedDate!.month,
      lastGeneratedDate!.day,
    );

    return lastGen.isAtSameMomentAs(today);
  }

  /// Converts the recurring expense to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'frequency': frequency.name,
      'customIntervalDays': customIntervalDays,
      'weekdays': weekdays,
      'dayOfMonth': dayOfMonth,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a RecurringExpense from a JSON map.
  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      customIntervalDays: json['customIntervalDays'] as int? ?? 1,
      weekdays: (json['weekdays'] as List<dynamic>?)?.cast<int>(),
      dayOfMonth: json['dayOfMonth'] as int?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      lastGeneratedDate: json['lastGeneratedDate'] != null
          ? DateTime.parse(json['lastGeneratedDate'] as String)
          : null,
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'RecurringExpense(id: $id, title: $title, amount: $amount, '
        'frequency: ${frequency.displayName}, isActive: $isActive)';
  }
}
