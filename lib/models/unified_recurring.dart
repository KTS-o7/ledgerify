import 'package:flutter/material.dart';
import 'recurring_expense.dart';
import 'recurring_income.dart';
import 'expense.dart';
import 'income.dart';

/// Enum representing the type of recurring item.
enum RecurringType { income, expense }

/// A unified wrapper model for displaying both recurring expenses and recurring income
/// in a single list or screen.
///
/// This provides a common interface for both types of recurring items,
/// making it easier to display them together with consistent computed properties.
class UnifiedRecurringItem {
  /// Unique identifier from the original item.
  final String id;

  /// Display title for the item.
  /// For expenses: the title field.
  /// For income: the source display name (or description if available).
  final String title;

  /// The recurring amount.
  final double amount;

  /// Whether this is income or expense.
  final RecurringType type;

  /// How often the item recurs.
  final RecurrenceFrequency frequency;

  /// The next date when this item is due.
  final DateTime nextDate;

  /// Whether the recurring item is currently active.
  final bool isActive;

  /// Icon to display for the item.
  final IconData icon;

  /// Optional custom color for the icon.
  final Color? iconColor;

  /// Optional note or description.
  final String? note;

  /// Reference to the original item (RecurringExpense or RecurringIncome).
  /// Use this when you need to access type-specific fields.
  final dynamic originalItem;

  const UnifiedRecurringItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextDate,
    required this.isActive,
    required this.icon,
    this.iconColor,
    this.note,
    required this.originalItem,
  });

  /// Creates a UnifiedRecurringItem from a RecurringExpense.
  factory UnifiedRecurringItem.fromExpense(RecurringExpense expense) {
    return UnifiedRecurringItem(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      type: RecurringType.expense,
      frequency: expense.frequency,
      nextDate: expense.nextDueDate,
      isActive: expense.isActive,
      icon: expense.category.icon,
      iconColor: null, // Uses default expense color from theme
      note: expense.note,
      originalItem: expense,
    );
  }

  /// Creates a UnifiedRecurringItem from a RecurringIncome.
  factory UnifiedRecurringItem.fromIncome(RecurringIncome income) {
    // For income title, prefer description if available, otherwise use source name
    final title = income.description?.isNotEmpty == true
        ? income.description!
        : income.source.displayName;

    return UnifiedRecurringItem(
      id: income.id,
      title: title,
      amount: income.amount,
      type: RecurringType.income,
      frequency: income.frequency,
      nextDate: income.nextDate,
      isActive: income.isActive,
      icon: income.source.icon,
      iconColor: null, // Uses default income color from theme
      note: income.description,
      originalItem: income,
    );
  }

  /// Returns the number of days until the next due date.
  /// Negative values indicate overdue days.
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return dueDate.difference(today).inDays;
  }

  /// Returns true if the item is due today or in the past.
  bool get isDue {
    if (!isActive) return false;
    return daysUntilDue <= 0;
  }

  /// Returns true if the item is overdue (past due date).
  bool get isOverdue {
    if (!isActive) return false;
    return daysUntilDue < 0;
  }

  /// Returns true if the item is due today.
  bool get isDueToday {
    if (!isActive) return false;
    return daysUntilDue == 0;
  }

  /// Returns true if the item is due tomorrow.
  bool get isDueTomorrow {
    if (!isActive) return false;
    return daysUntilDue == 1;
  }

  /// Returns a human-readable description of the recurrence frequency.
  String get frequencyDescription {
    if (type == RecurringType.expense) {
      // RecurringExpense has a detailed frequencyDescription getter
      return (originalItem as RecurringExpense).frequencyDescription;
    }

    // For income, use the basic frequency display name
    return frequency.displayName;
  }

  /// Returns a human-readable description of when the item is due.
  ///
  /// Examples:
  /// - "Due today"
  /// - "Due tomorrow"
  /// - "Due in 2 days"
  /// - "Due in 5 days"
  /// - "Overdue"
  /// - "Overdue by 3 days"
  String get dueDescription {
    if (!isActive) {
      return 'Paused';
    }

    final days = daysUntilDue;

    if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else if (days > 1) {
      return 'Due in $days days';
    } else if (days == -1) {
      return 'Overdue by 1 day';
    } else {
      // days < -1
      return 'Overdue by ${-days} days';
    }
  }

  /// Returns the original item as a RecurringExpense.
  /// Throws if the item is not an expense.
  RecurringExpense get asExpense {
    if (type != RecurringType.expense) {
      throw StateError('Cannot access asExpense on an income item');
    }
    return originalItem as RecurringExpense;
  }

  /// Returns the original item as a RecurringIncome.
  /// Throws if the item is not an income.
  RecurringIncome get asIncome {
    if (type != RecurringType.income) {
      throw StateError('Cannot access asIncome on an expense item');
    }
    return originalItem as RecurringIncome;
  }

  @override
  String toString() {
    return 'UnifiedRecurringItem(id: $id, title: $title, amount: $amount, '
        'type: ${type.name}, frequency: ${frequency.displayName}, '
        'isActive: $isActive, dueDescription: $dueDescription)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedRecurringItem &&
        other.id == id &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}
