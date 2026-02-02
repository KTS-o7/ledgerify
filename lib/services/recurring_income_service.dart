import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/income.dart';
import '../models/recurring_income.dart';
import '../models/recurring_expense.dart'; // For RecurrenceFrequency
import 'income_service.dart';

/// Service class for managing recurring income entries with Hive local storage.
///
/// This service provides CRUD operations for recurring income templates
/// and handles the automatic generation of actual income entries based on
/// recurrence patterns.
class RecurringIncomeService {
  static const String _lastGenerationKey = 'last_recurring_income_generation';
  static const Uuid _uuid = Uuid();

  final Box<RecurringIncome> _box;

  /// Creates a new RecurringIncomeService with the provided Hive box.
  RecurringIncomeService(this._box);

  /// Returns the listenable box for reactive UI updates with ValueListenableBuilder.
  Box<RecurringIncome> get box => _box;

  // ============================================
  // CRUD Operations
  // ============================================

  /// Generates a new unique ID for a recurring income.
  String generateId() => _uuid.v4();

  /// Retrieves all recurring incomes, sorted by nextDate.
  List<RecurringIncome> getAllRecurringIncomes() {
    final items = _box.values.toList();
    items.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return items;
  }

  /// Retrieves all active recurring incomes, sorted by nextDate.
  List<RecurringIncome> getActiveRecurringIncomes() {
    final active = <RecurringIncome>[];
    for (final item in _box.values) {
      if (item.isActive) {
        active.add(item);
      }
    }
    active.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return active;
  }

  /// Retrieves a single recurring income by ID.
  /// Returns null if not found.
  RecurringIncome? getRecurringIncome(String id) {
    return _box.get(id);
  }

  /// Creates a new recurring income entry.
  /// Returns the created recurring income.
  Future<RecurringIncome> createRecurringIncome({
    required double amount,
    required IncomeSource source,
    String? description,
    required RecurrenceFrequency frequency,
    required DateTime nextDate,
    List<GoalAllocation>? goalAllocations,
  }) async {
    final recurring = RecurringIncome(
      id: generateId(),
      amount: amount,
      source: source,
      description: description,
      frequency: frequency,
      nextDate: nextDate,
      goalAllocations: goalAllocations ?? [],
    );

    await _box.put(recurring.id, recurring);
    return recurring;
  }

  /// Updates an existing recurring income.
  Future<void> updateRecurringIncome(RecurringIncome income) async {
    await _box.put(income.id, income);
  }

  /// Deletes a recurring income by ID.
  Future<void> deleteRecurringIncome(String id) async {
    await _box.delete(id);
  }

  /// Toggles the isActive status of a recurring income.
  Future<void> toggleActive(String id) async {
    final item = getRecurringIncome(id);
    if (item != null) {
      final updated = item.copyWith(isActive: !item.isActive);
      await updateRecurringIncome(updated);
    }
  }

  // ============================================
  // Generation Logic
  // ============================================

  /// Generates incomes for all due recurring items if not already generated recently.
  ///
  /// This is the preferred method to call from main.dart. It will skip generation
  /// if already run within the last hour to avoid redundant processing on app restarts.
  ///
  /// Returns the count of generated incomes, or 0 if skipped.
  Future<int> generateDueIncomesIfNeeded(IncomeService incomeService) async {
    final settingsBox = Hive.box('settings');
    final lastGen = settingsBox.get(_lastGenerationKey) as DateTime?;
    final now = DateTime.now();

    // Skip if generated within last hour
    if (lastGen != null && now.difference(lastGen).inHours < 1) {
      return 0;
    }

    await generateDueIncomes(incomeService);
    await settingsBox.put(_lastGenerationKey, now);
    // Return count of due items that were processed
    return getDueIncomes().length;
  }

  /// Gets all recurring incomes that are due (nextDate <= today).
  List<RecurringIncome> getDueIncomes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = <RecurringIncome>[];
    for (final item in _box.values) {
      if (!item.isActive) continue;

      final nextDate = DateTime(
        item.nextDate.year,
        item.nextDate.month,
        item.nextDate.day,
      );

      if (!nextDate.isAfter(today)) {
        due.add(item);
      }
    }

    due.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return due;
  }

  /// Generates Income entries for all due recurring incomes and advances nextDate.
  ///
  /// This should be called when the app opens. It will:
  /// 1. Find all active recurring incomes that are due
  /// 2. Generate actual [Income] entries for each via incomeService
  /// 3. Update the lastGeneratedDate and nextDate
  Future<void> generateDueIncomes(IncomeService incomeService) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final recurring in getDueIncomes()) {
      // Skip if already generated today
      if (recurring.lastGeneratedDate != null) {
        final lastGen = DateTime(
          recurring.lastGeneratedDate!.year,
          recurring.lastGeneratedDate!.month,
          recurring.lastGeneratedDate!.day,
        );
        if (lastGen.isAtSameMomentAs(today)) {
          continue;
        }
      }

      // Generate income for all missed dates (catch-up)
      var currentDueDate = DateTime(
        recurring.nextDate.year,
        recurring.nextDate.month,
        recurring.nextDate.day,
      );

      while (!currentDueDate.isAfter(today)) {
        // Generate the income entry via incomeService
        await incomeService.addIncome(
          amount: recurring.amount,
          source: recurring.source,
          description: recurring.description,
          date: currentDueDate,
          goalAllocations: recurring.goalAllocations,
          recurringIncomeId: recurring.id,
        );

        // Calculate the next due date
        currentDueDate =
            _calculateNextDate(currentDueDate, recurring.frequency);
      }

      // Update the recurring income with new dates
      final updated = recurring.copyWith(
        lastGeneratedDate: today,
        nextDate: currentDueDate,
      );
      await updateRecurringIncome(updated);
    }
  }

  /// Calculates the next occurrence date based on frequency.
  DateTime _calculateNextDate(DateTime from, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));

      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));

      case RecurrenceFrequency.monthly:
        return _addMonths(from, 1);

      case RecurrenceFrequency.yearly:
        return _addYears(from, 1);

      case RecurrenceFrequency.custom:
        // For custom, default to 1 day if no interval specified
        return from.add(const Duration(days: 1));
    }
  }

  /// Adds months to a date, handling day overflow.
  DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;

    while (month > 12) {
      month -= 12;
      year++;
    }

    final day = _clampDay(year, month, date.day);
    return DateTime(year, month, day);
  }

  /// Adds years to a date.
  DateTime _addYears(DateTime date, int years) {
    final newYear = date.year + years;
    final adjustedDay = _clampDay(newYear, date.month, date.day);
    return DateTime(newYear, date.month, adjustedDay);
  }

  /// Clamps a day to the valid range for a month.
  int _clampDay(int year, int month, int day) {
    final maxDay = _daysInMonth(year, month);
    return day > maxDay ? maxDay : day;
  }

  /// Returns the number of days in a month.
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Returns count of incomes due within N days (default 7).
  int getUpcomingCount({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: days));

    int count = 0;
    for (final item in _box.values) {
      if (!item.isActive) continue;

      final nextDate = DateTime(
        item.nextDate.year,
        item.nextDate.month,
        item.nextDate.day,
      );

      if (!nextDate.isAfter(endDate)) {
        count++;
      }
    }
    return count;
  }

  /// Estimates expected monthly income from all active recurring incomes.
  ///
  /// This calculates an approximate monthly value by converting each
  /// recurring income's frequency to a monthly equivalent.
  double getExpectedMonthlyIncome() {
    double total = 0.0;

    for (final item in _box.values) {
      if (!item.isActive) continue;

      switch (item.frequency) {
        case RecurrenceFrequency.daily:
          // ~30 days per month
          total += item.amount * 30;
          break;

        case RecurrenceFrequency.weekly:
          // ~4.33 weeks per month
          total += item.amount * 4.33;
          break;

        case RecurrenceFrequency.monthly:
          total += item.amount;
          break;

        case RecurrenceFrequency.yearly:
          // Divide by 12 for monthly equivalent
          total += item.amount / 12;
          break;

        case RecurrenceFrequency.custom:
          // Assume daily for custom without interval
          total += item.amount * 30;
          break;
      }
    }

    return total;
  }

  /// Returns the count of all recurring incomes.
  int get count => _box.length;

  /// Checks if there are any recurring incomes.
  bool get isEmpty => _box.isEmpty;

  /// Checks if there are recurring incomes.
  bool get isNotEmpty => _box.isNotEmpty;

  /// Clears all recurring incomes (use with caution!).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
