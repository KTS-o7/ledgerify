import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/recurring_expense.dart';
import 'expense_service.dart';

/// Service class for managing recurring expenses with Hive local storage.
///
/// This service provides CRUD operations for recurring expense templates
/// and handles the automatic generation of actual expenses based on
/// recurrence patterns.
class RecurringExpenseService {
  static const String _boxName = 'recurring_expenses';
  static const Uuid _uuid = Uuid();

  late Box<RecurringExpense> _box;

  /// Initializes Hive and opens the recurring expenses box.
  /// Must be called before any other operations.
  Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(RecurrenceFrequencyAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(RecurringExpenseAdapter());
    }

    // Open the recurring expenses box
    _box = await Hive.openBox<RecurringExpense>(_boxName);
  }

  /// Generates a new unique ID for a recurring expense.
  String generateId() => _uuid.v4();

  // ============================================
  // CRUD Operations
  // ============================================

  /// Adds a new recurring expense.
  /// Returns the created recurring expense.
  Future<RecurringExpense> add({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required RecurrenceFrequency frequency,
    int customIntervalDays = 1,
    List<int>? weekdays,
    int? dayOfMonth,
    required DateTime startDate,
    DateTime? endDate,
    String? note,
  }) async {
    // Calculate the first due date
    final nextDueDate = _calculateInitialDueDate(
      frequency: frequency,
      startDate: startDate,
      customIntervalDays: customIntervalDays,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
    );

    final recurring = RecurringExpense(
      id: generateId(),
      title: title,
      amount: amount,
      category: category,
      frequency: frequency,
      customIntervalDays: customIntervalDays,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
      endDate: endDate,
      nextDueDate: nextDueDate,
      note: note,
    );

    await _box.put(recurring.id, recurring);
    return recurring;
  }

  /// Updates an existing recurring expense.
  /// Returns the updated recurring expense.
  Future<RecurringExpense> update(RecurringExpense recurring) async {
    await _box.put(recurring.id, recurring);
    return recurring;
  }

  /// Deletes a recurring expense by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Retrieves a single recurring expense by ID.
  /// Returns null if not found.
  RecurringExpense? get(String id) {
    return _box.get(id);
  }

  /// Retrieves all recurring expenses, sorted by title.
  List<RecurringExpense> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }

  // ============================================
  // Filtering
  // ============================================

  /// Retrieves all active recurring expenses.
  List<RecurringExpense> getActive() {
    return getAll().where((item) => item.isActive && !item.hasEnded).toList();
  }

  /// Retrieves all paused recurring expenses.
  List<RecurringExpense> getPaused() {
    return getAll().where((item) => !item.isActive && !item.hasEnded).toList();
  }

  /// Retrieves all ended recurring expenses.
  List<RecurringExpense> getEnded() {
    return getAll().where((item) => item.hasEnded).toList();
  }

  /// Retrieves upcoming recurring expenses within the specified number of days.
  /// Sorted by nextDueDate.
  List<RecurringExpense> getUpcoming({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: days));

    final upcoming = getActive().where((item) {
      final dueDate = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );
      return !dueDate.isAfter(endDate);
    }).toList();

    upcoming.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return upcoming;
  }

  // ============================================
  // State Management
  // ============================================

  /// Pauses a recurring expense.
  Future<void> pause(String id) async {
    final item = get(id);
    if (item != null) {
      await update(item.copyWith(isActive: false));
    }
  }

  /// Resumes a recurring expense.
  Future<void> resume(String id) async {
    final item = get(id);
    if (item != null) {
      // Recalculate next due date from today when resuming
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextDue = calculateNextDueDate(item, from: today);
      await update(item.copyWith(isActive: true, nextDueDate: nextDue));
    }
  }

  // ============================================
  // Generation
  // ============================================

  /// Generates expenses for all due recurring items.
  ///
  /// This should be called when the app opens. It will:
  /// 1. Find all active recurring expenses that are due
  /// 2. Generate actual [Expense] entries for each
  /// 3. Update the lastGeneratedDate and nextDueDate
  ///
  /// Returns the list of generated expenses.
  Future<List<Expense>> generateDueExpenses(
      ExpenseService expenseService) async {
    final generated = <Expense>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final recurring in getActive()) {
      // Skip if already generated today
      if (recurring.alreadyGeneratedToday) {
        continue;
      }

      // Skip if not yet due
      if (!recurring.isDue) {
        continue;
      }

      // Generate expenses for all missed dates (catch-up)
      var currentDueDate = DateTime(
        recurring.nextDueDate.year,
        recurring.nextDueDate.month,
        recurring.nextDueDate.day,
      );

      while (!currentDueDate.isAfter(today)) {
        // Check if we've passed the end date
        if (recurring.endDate != null) {
          final endDate = DateTime(
            recurring.endDate!.year,
            recurring.endDate!.month,
            recurring.endDate!.day,
          );
          if (currentDueDate.isAfter(endDate)) {
            break;
          }
        }

        // Generate the expense
        final expense = await expenseService.addExpense(
          amount: recurring.amount,
          category: recurring.category,
          date: currentDueDate,
          note: _buildExpenseNote(recurring),
          source: ExpenseSource.recurring,
          merchant: recurring.title,
        );
        generated.add(expense);

        // Calculate the next due date
        currentDueDate = calculateNextDueDate(
          recurring,
          from: currentDueDate,
        );
      }

      // Update the recurring expense with new dates
      await update(recurring.copyWith(
        lastGeneratedDate: today,
        nextDueDate: currentDueDate,
      ));
    }

    return generated;
  }

  /// Builds the note for a generated expense.
  String? _buildExpenseNote(RecurringExpense recurring) {
    if (recurring.note != null && recurring.note!.isNotEmpty) {
      return '[${recurring.title}] ${recurring.note}';
    }
    return '[${recurring.title}] ${recurring.frequencyDescription}';
  }

  // ============================================
  // Date Calculation
  // ============================================

  /// Calculates the next due date for a recurring expense.
  ///
  /// [from] is the base date to calculate from (defaults to nextDueDate).
  DateTime calculateNextDueDate(RecurringExpense item, {DateTime? from}) {
    final baseDate = from ?? item.nextDueDate;

    switch (item.frequency) {
      case RecurrenceFrequency.daily:
        return _addDays(baseDate, 1);

      case RecurrenceFrequency.weekly:
        if (item.weekdays != null && item.weekdays!.isNotEmpty) {
          return _findNextWeekday(baseDate, item.weekdays!);
        }
        return _addDays(baseDate, 7);

      case RecurrenceFrequency.monthly:
        return _addMonths(baseDate, 1, item.dayOfMonth);

      case RecurrenceFrequency.yearly:
        return _addYears(baseDate, 1);

      case RecurrenceFrequency.custom:
        return _addDays(baseDate, item.customIntervalDays);
    }
  }

  /// Calculates the initial due date for a new recurring expense.
  DateTime _calculateInitialDueDate({
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    int customIntervalDays = 1,
    List<int>? weekdays,
    int? dayOfMonth,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // If start date is in the future, use it
    if (start.isAfter(today)) {
      // For weekly with specific weekdays, find the first matching day
      if (frequency == RecurrenceFrequency.weekly &&
          weekdays != null &&
          weekdays.isNotEmpty) {
        return _findNextWeekdayFrom(start, weekdays, inclusive: true);
      }
      // For monthly with specific day, adjust to that day
      if (frequency == RecurrenceFrequency.monthly && dayOfMonth != null) {
        return _adjustToDay(start, dayOfMonth);
      }
      return start;
    }

    // Start date is today or in the past, calculate next occurrence
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return today;

      case RecurrenceFrequency.weekly:
        if (weekdays != null && weekdays.isNotEmpty) {
          return _findNextWeekdayFrom(today, weekdays, inclusive: true);
        }
        // Same weekday as start date
        return _findNextSpecificWeekday(today, start.weekday, inclusive: true);

      case RecurrenceFrequency.monthly:
        final targetDay = dayOfMonth ?? start.day;
        return _findNextMonthlyDate(today, targetDay, inclusive: true);

      case RecurrenceFrequency.yearly:
        return _findNextYearlyDate(today, start.month, start.day,
            inclusive: true);

      case RecurrenceFrequency.custom:
        // Calculate how many intervals have passed since start
        final daysSinceStart = today.difference(start).inDays;
        final intervalsPassed = daysSinceStart ~/ customIntervalDays;
        var nextDate =
            start.add(Duration(days: intervalsPassed * customIntervalDays));
        if (!nextDate.isAfter(today) && nextDate != today) {
          nextDate = nextDate.add(Duration(days: customIntervalDays));
        }
        return nextDate.isBefore(today) ? today : nextDate;
    }
  }

  /// Adds days to a date.
  DateTime _addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Adds months to a date, handling day overflow.
  DateTime _addMonths(DateTime date, int months, int? targetDay) {
    var year = date.year;
    var month = date.month + months;

    while (month > 12) {
      month -= 12;
      year++;
    }

    // Determine the target day
    final day = targetDay ?? date.day;
    final adjustedDay = _clampDay(year, month, day);

    return DateTime(year, month, adjustedDay);
  }

  /// Adds years to a date.
  DateTime _addYears(DateTime date, int years) {
    final newYear = date.year + years;
    final adjustedDay = _clampDay(newYear, date.month, date.day);
    return DateTime(newYear, date.month, adjustedDay);
  }

  /// Clamps a day to the valid range for a month.
  int _clampDay(int year, int month, int day) {
    // Handle "last day of month" special value
    if (day == 32) {
      return _daysInMonth(year, month);
    }
    final maxDay = _daysInMonth(year, month);
    return day > maxDay ? maxDay : day;
  }

  /// Returns the number of days in a month.
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Finds the next weekday from a list of weekdays.
  DateTime _findNextWeekday(DateTime from, List<int> weekdays) {
    return _findNextWeekdayFrom(from.add(const Duration(days: 1)), weekdays,
        inclusive: true);
  }

  /// Finds the next weekday from a list, optionally including the start date.
  DateTime _findNextWeekdayFrom(DateTime from, List<int> weekdays,
      {bool inclusive = false}) {
    var current = from;
    if (!inclusive) {
      current = current.add(const Duration(days: 1));
    }

    // Search up to 8 days (guarantees finding a match)
    for (var i = 0; i < 8; i++) {
      // DateTime.weekday: 1=Monday, 7=Sunday (matches our format)
      if (weekdays.contains(current.weekday)) {
        return DateTime(current.year, current.month, current.day);
      }
      current = current.add(const Duration(days: 1));
    }

    // Fallback (shouldn't happen with valid weekdays)
    return from.add(const Duration(days: 7));
  }

  /// Finds the next occurrence of a specific weekday.
  DateTime _findNextSpecificWeekday(DateTime from, int weekday,
      {bool inclusive = false}) {
    var current = from;
    if (!inclusive) {
      current = current.add(const Duration(days: 1));
    }

    while (current.weekday != weekday) {
      current = current.add(const Duration(days: 1));
    }

    return DateTime(current.year, current.month, current.day);
  }

  /// Finds the next monthly date with the given target day.
  DateTime _findNextMonthlyDate(DateTime from, int targetDay,
      {bool inclusive = false}) {
    var year = from.year;
    var month = from.month;
    var day = _clampDay(year, month, targetDay);

    var candidate = DateTime(year, month, day);

    if (inclusive &&
        candidate.isAtSameMomentAs(DateTime(from.year, from.month, from.day))) {
      return candidate;
    }

    if (!candidate.isAfter(from)) {
      // Move to next month
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      day = _clampDay(year, month, targetDay);
      candidate = DateTime(year, month, day);
    }

    return candidate;
  }

  /// Finds the next yearly date with the given target month and day.
  DateTime _findNextYearlyDate(DateTime from, int targetMonth, int targetDay,
      {bool inclusive = false}) {
    var year = from.year;
    var day = _clampDay(year, targetMonth, targetDay);
    var candidate = DateTime(year, targetMonth, day);

    if (inclusive &&
        candidate.isAtSameMomentAs(DateTime(from.year, from.month, from.day))) {
      return candidate;
    }

    if (!candidate.isAfter(from)) {
      year++;
      day = _clampDay(year, targetMonth, targetDay);
      candidate = DateTime(year, targetMonth, day);
    }

    return candidate;
  }

  /// Adjusts a date to a specific day of month.
  DateTime _adjustToDay(DateTime date, int targetDay) {
    final day = _clampDay(date.year, date.month, targetDay);
    return DateTime(date.year, date.month, day);
  }

  // ============================================
  // Utilities
  // ============================================

  /// Returns the listenable box for reactive UI updates.
  Box<RecurringExpense> get box => _box;

  /// Clears all recurring expenses (use with caution!).
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Returns the count of all recurring expenses.
  int get count => _box.length;

  /// Checks if there are any recurring expenses.
  bool get isEmpty => _box.isEmpty;

  /// Checks if there are recurring expenses.
  bool get isNotEmpty => _box.isNotEmpty;
}
