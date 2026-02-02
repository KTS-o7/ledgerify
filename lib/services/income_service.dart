import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/income.dart';
import 'goal_service.dart';

/// Service class for managing income entries with Hive local storage.
///
/// This service provides CRUD operations for income entries, including
/// goal allocation management. When income is added with allocations,
/// contributions are automatically applied to the associated goals.
class IncomeService {
  static const Uuid _uuid = Uuid();

  final Box<Income> _incomeBox;
  final GoalService _goalService;

  /// Creates an IncomeService with the given Hive box and GoalService.
  IncomeService(this._incomeBox, this._goalService);

  /// Returns the listenable box for reactive UI updates.
  /// Use this with ValueListenableBuilder to rebuild UI on data changes.
  Box<Income> get box => _incomeBox;

  /// Generates a new unique ID for an income entry.
  String generateId() => _uuid.v4();

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Retrieves all incomes, sorted by date (newest first).
  List<Income> getAllIncomes() {
    final incomes = _incomeBox.values.toList();
    incomes.sort((a, b) => b.date.compareTo(a.date));
    return incomes;
  }

  /// Retrieves incomes for a specific month and year.
  /// Sorted by date (newest first).
  List<Income> getIncomesForMonth(int year, int month) {
    final monthIncomes = _incomeBox.values.where((income) {
      return income.date.year == year && income.date.month == month;
    }).toList();
    monthIncomes.sort((a, b) => b.date.compareTo(a.date));
    return monthIncomes;
  }

  /// Retrieves a single income by ID.
  /// Returns null if not found.
  Income? getIncome(String id) {
    return _incomeBox.get(id);
  }

  /// Adds a new income entry with optional goal allocations.
  ///
  /// If [goalAllocations] is provided, contributions are automatically
  /// applied to the associated goals via GoalService.
  ///
  /// Returns the created income entry.
  Future<Income> addIncome({
    required double amount,
    required IncomeSource source,
    String? description,
    required DateTime date,
    List<GoalAllocation>? goalAllocations,
    String? recurringIncomeId,
  }) async {
    final income = Income(
      id: generateId(),
      amount: amount,
      source: source,
      description: description,
      date: date,
      goalAllocations: goalAllocations ?? [],
      recurringIncomeId: recurringIncomeId,
    );

    await _incomeBox.put(income.id, income);

    // Apply goal allocations
    if (income.hasAllocations) {
      await _applyAllocations(income.goalAllocations);
    }

    return income;
  }

  /// Updates an existing income entry.
  ///
  /// If allocations have changed, this method will:
  /// 1. Reverse the old allocations (remove contributions from goals)
  /// 2. Apply the new allocations (add contributions to goals)
  Future<void> updateIncome(Income income) async {
    final oldIncome = _incomeBox.get(income.id);

    // Reverse old allocations if they existed
    if (oldIncome != null && oldIncome.hasAllocations) {
      await _reverseAllocations(oldIncome.goalAllocations);
    }

    // Save the updated income
    await _incomeBox.put(income.id, income);

    // Apply new allocations
    if (income.hasAllocations) {
      await _applyAllocations(income.goalAllocations);
    }
  }

  /// Deletes an income entry by ID.
  ///
  /// Automatically reverses any goal allocations associated with
  /// the income entry being deleted.
  Future<void> deleteIncome(String id) async {
    final income = _incomeBox.get(id);

    if (income != null && income.hasAllocations) {
      await _reverseAllocations(income.goalAllocations);
    }

    await _incomeBox.delete(id);
  }

  // ============================================================================
  // Goal Allocation Logic
  // ============================================================================

  /// Calculates allocation amounts from percentages.
  ///
  /// Takes an income amount and a list of allocation specifications
  /// (goalId + percentage) and returns a list of [GoalAllocation] objects
  /// with calculated amounts.
  ///
  /// Example:
  /// ```dart
  /// final allocations = service.calculateAllocations(10000, [
  ///   (goalId: 'goal-1', percentage: 20.0), // 2000
  ///   (goalId: 'goal-2', percentage: 10.0), // 1000
  /// ]);
  /// ```
  List<GoalAllocation> calculateAllocations(
    double amount,
    List<({String goalId, double percentage})> allocations,
  ) {
    return allocations.map((spec) {
      final allocatedAmount = (amount * spec.percentage) / 100.0;
      return GoalAllocation(
        goalId: spec.goalId,
        percentage: spec.percentage,
        amount: allocatedAmount,
      );
    }).toList();
  }

  /// Applies goal allocations by adding contributions to goals via GoalService.
  Future<void> _applyAllocations(List<GoalAllocation> allocations) async {
    for (final allocation in allocations) {
      await _goalService.addContribution(allocation.goalId, allocation.amount);
    }
  }

  /// Reverses goal allocations by withdrawing contributions from goals.
  ///
  /// Used when deleting an income entry or updating allocations.
  Future<void> _reverseAllocations(List<GoalAllocation> allocations) async {
    for (final allocation in allocations) {
      await _goalService.withdrawContribution(
          allocation.goalId, allocation.amount);
    }
  }

  // ============================================================================
  // Analytics
  // ============================================================================

  /// Returns a complete month summary in a single pass.
  /// This is more efficient than calling getIncomesForMonth and
  /// getTotalIncomeForMonth separately.
  IncomeSummary getMonthSummary(int year, int month) {
    final incomes = <Income>[];
    double total = 0;

    // Single pass through the data
    for (final income in _incomeBox.values) {
      if (income.date.year == year && income.date.month == month) {
        incomes.add(income);
        total += income.amount;
      }
    }

    // Sort incomes by date (newest first)
    incomes.sort((a, b) => b.date.compareTo(a.date));

    return IncomeSummary(
      incomes: incomes,
      total: total,
      count: incomes.length,
    );
  }

  /// Returns the total income for a specific month.
  double getTotalIncomeForMonth(int year, int month) {
    double total = 0.0;

    for (final income in _incomeBox.values) {
      if (income.date.year == year && income.date.month == month) {
        total += income.amount;
      }
    }

    return total;
  }

  /// Returns income breakdown by source for a specific month.
  ///
  /// Returns a map where keys are [IncomeSource] values and
  /// values are the total income from that source.
  Map<IncomeSource, double> getIncomeBySource(int year, int month) {
    final breakdown = <IncomeSource, double>{};

    for (final income in _incomeBox.values) {
      if (income.date.year == year && income.date.month == month) {
        breakdown[income.source] =
            (breakdown[income.source] ?? 0) + income.amount;
      }
    }

    return breakdown;
  }

  /// Returns the total income for a date range.
  double getTotalIncomeForRange(DateTime start, DateTime end) {
    double total = 0.0;

    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    for (final income in _incomeBox.values) {
      final incomeDate = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      if (!incomeDate.isBefore(startDate) && !incomeDate.isAfter(endDate)) {
        total += income.amount;
      }
    }

    return total;
  }

  /// Returns income breakdown by source for a date range.
  Map<IncomeSource, double> getIncomeBySourceForRange(
    DateTime start,
    DateTime end,
  ) {
    final breakdown = <IncomeSource, double>{};

    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    for (final income in _incomeBox.values) {
      final incomeDate = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      if (!incomeDate.isBefore(startDate) && !incomeDate.isAfter(endDate)) {
        breakdown[income.source] =
            (breakdown[income.source] ?? 0) + income.amount;
      }
    }

    return breakdown;
  }

  /// Returns monthly income totals for the last N months.
  /// Returns a list of (year, month, total) records sorted chronologically.
  /// Optimized: Single pass through all incomes instead of N iterations.
  List<MonthlyIncome> getMonthlyTotals(int months) {
    // Guard clause for invalid input
    if (months <= 0) return [];

    final now = DateTime.now();

    // Calculate the start month
    var startYear = now.year;
    var startMonth = now.month - (months - 1);
    while (startMonth <= 0) {
      startMonth += 12;
      startYear--;
    }

    // Pre-populate all N months with 0 total
    final monthlyTotals = <String, double>{};
    var year = startYear;
    var month = startMonth;
    for (var i = 0; i < months; i++) {
      final key = '$year-$month';
      monthlyTotals[key] = 0;
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    // Single pass through all incomes
    for (final income in _incomeBox.values) {
      final incYear = income.date.year;
      final incMonth = income.date.month;

      // Check if income is within our date range
      final isAfterOrEqualStart = incYear > startYear ||
          (incYear == startYear && incMonth >= startMonth);
      final isBeforeOrEqualEnd =
          incYear < now.year || (incYear == now.year && incMonth <= now.month);

      if (!isAfterOrEqualStart || !isBeforeOrEqualEnd) {
        continue;
      }

      final key = '$incYear-$incMonth';
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + income.amount;
    }

    // Convert to list of MonthlyIncome and sort ascending
    final results = monthlyTotals.entries.map((e) {
      final parts = e.key.split('-');
      return MonthlyIncome(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        total: e.value,
      );
    }).toList();

    // Sort by year then month (ascending)
    results.sort((a, b) {
      final yearCompare = a.year.compareTo(b.year);
      if (yearCompare != 0) return yearCompare;
      return a.month.compareTo(b.month);
    });

    return results;
  }
}

/// Record for monthly income total
class MonthlyIncome {
  final int year;
  final int month;
  final double total;

  const MonthlyIncome({
    required this.year,
    required this.month,
    required this.total,
  });
}

/// Holds pre-computed summary data for a month's income.
/// Used for efficient single-pass data retrieval.
class IncomeSummary {
  final List<Income> incomes;
  final double total;
  final int count;

  const IncomeSummary({
    required this.incomes,
    required this.total,
    required this.count,
  });
}
