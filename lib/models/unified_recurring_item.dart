import 'package:flutter/material.dart';
import 'recurring_expense.dart';
import 'recurring_income.dart';
import 'expense.dart';
import 'income.dart';

/// Enum to distinguish between income and expense recurring items.
enum RecurringItemType {
  income,
  expense,
}

/// A unified wrapper that can represent either a RecurringIncome or RecurringExpense.
///
/// This allows displaying both types in a single list with consistent UI treatment.
/// The wrapper provides a common interface for accessing properties needed by
/// the UnifiedRecurringTile widget.
///
/// Usage:
/// ```dart
/// // From a RecurringIncome
/// final item = UnifiedRecurringItem.fromIncome(recurringIncome);
///
/// // From a RecurringExpense
/// final item = UnifiedRecurringItem.fromExpense(recurringExpense);
/// ```
class UnifiedRecurringItem {
  /// Unique identifier from the underlying model.
  final String id;

  /// Display title (source name for income, title for expense).
  final String title;

  /// The recurring amount.
  final double amount;

  /// Whether this is income or expense.
  final RecurringItemType type;

  /// The recurrence frequency.
  final RecurrenceFrequency frequency;

  /// The next expected date.
  final DateTime nextDate;

  /// Whether the recurring item is active (not paused).
  final bool isActive;

  /// The icon to display.
  final IconData icon;

  /// Number of goal allocations (income only).
  final int goalAllocationCount;

  /// Optional description or note.
  final String? description;

  /// Reference to the original RecurringIncome (if income type).
  final RecurringIncome? _recurringIncome;

  /// Reference to the original RecurringExpense (if expense type).
  final RecurringExpense? _recurringExpense;

  const UnifiedRecurringItem._({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextDate,
    required this.isActive,
    required this.icon,
    required this.goalAllocationCount,
    this.description,
    RecurringIncome? recurringIncome,
    RecurringExpense? recurringExpense,
  })  : _recurringIncome = recurringIncome,
        _recurringExpense = recurringExpense;

  /// Creates a UnifiedRecurringItem from a RecurringIncome.
  factory UnifiedRecurringItem.fromIncome(RecurringIncome income) {
    return UnifiedRecurringItem._(
      id: income.id,
      title: income.source.displayName,
      amount: income.amount,
      type: RecurringItemType.income,
      frequency: income.frequency,
      nextDate: income.nextDate,
      isActive: income.isActive,
      icon: income.source.icon,
      goalAllocationCount: income.goalAllocations.length,
      description: income.description,
      recurringIncome: income,
    );
  }

  /// Creates a UnifiedRecurringItem from a RecurringExpense.
  factory UnifiedRecurringItem.fromExpense(RecurringExpense expense) {
    return UnifiedRecurringItem._(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      type: RecurringItemType.expense,
      frequency: expense.frequency,
      nextDate: expense.nextDueDate,
      isActive: expense.isActive,
      icon: expense.category.icon,
      goalAllocationCount: 0,
      description: expense.note,
      recurringExpense: expense,
    );
  }

  /// Whether this item represents income.
  bool get isIncome => type == RecurringItemType.income;

  /// Whether this item represents an expense.
  bool get isExpense => type == RecurringItemType.expense;

  /// Returns the original RecurringIncome if this is an income item.
  RecurringIncome? get asRecurringIncome => _recurringIncome;

  /// Returns the original RecurringExpense if this is an expense item.
  RecurringExpense? get asRecurringExpense => _recurringExpense;

  /// Returns a human-readable frequency label.
  String get frequencyLabel => frequency.displayName;

  /// Returns true if the item is due today or in the past.
  bool get isDue {
    if (!isActive) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return !dueDate.isAfter(today);
  }

  /// Returns the number of days until the next date.
  /// Negative values indicate overdue days.
  int get daysUntilNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return dueDate.difference(today).inDays;
  }

  /// Returns true if the item is due within the specified number of days.
  bool isDueSoon([int days = 3]) {
    if (!isActive) return false;
    return daysUntilNext <= days;
  }

  @override
  String toString() {
    return 'UnifiedRecurringItem(id: $id, title: $title, type: ${type.name}, '
        'amount: $amount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedRecurringItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

/// Extension to create a list of UnifiedRecurringItems from separate lists.
extension UnifiedRecurringItemList on Iterable<UnifiedRecurringItem> {
  /// Sorts items by next date (soonest first).
  List<UnifiedRecurringItem> sortedByNextDate() {
    final list = toList();
    list.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return list;
  }

  /// Filters to only active items.
  Iterable<UnifiedRecurringItem> get active => where((item) => item.isActive);

  /// Filters to only paused items.
  Iterable<UnifiedRecurringItem> get paused => where((item) => !item.isActive);

  /// Filters to only income items.
  Iterable<UnifiedRecurringItem> get incomeOnly =>
      where((item) => item.isIncome);

  /// Filters to only expense items.
  Iterable<UnifiedRecurringItem> get expenseOnly =>
      where((item) => item.isExpense);

  /// Filters to items due soon (within specified days).
  Iterable<UnifiedRecurringItem> dueSoon([int days = 3]) =>
      where((item) => item.isDueSoon(days));
}

/// Helper to combine income and expense lists into unified items.
class UnifiedRecurringItemFactory {
  UnifiedRecurringItemFactory._();

  /// Creates a combined list from both recurring incomes and expenses.
  static List<UnifiedRecurringItem> fromLists({
    required List<RecurringIncome> incomes,
    required List<RecurringExpense> expenses,
    bool sortByNextDate = true,
  }) {
    final items = <UnifiedRecurringItem>[
      ...incomes.map(UnifiedRecurringItem.fromIncome),
      ...expenses.map(UnifiedRecurringItem.fromExpense),
    ];

    if (sortByNextDate) {
      items.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    }

    return items;
  }
}
