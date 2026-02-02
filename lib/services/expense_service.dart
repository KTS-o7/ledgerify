import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/expense_template.dart';
import '../utils/currency_formatter.dart';
import 'budget_service.dart';
import 'notification_service.dart';

/// Spending pace status for month comparison
enum SpendingPaceStatus { onTrack, faster, slower }

/// Represents spending pace analysis for a month
class SpendingPace {
  /// Total spent so far this month
  final double currentTotal;

  /// Projected end-of-month total based on current daily rate
  final double projectedTotal;

  /// Average monthly spending (from past 3 months, or however many available)
  final double averageMonthlyTotal;

  /// Number of months used to calculate the average (1-3)
  final int monthsInAverage;

  /// Current daily spending rate
  final double dailyAverage;

  /// Days elapsed in the month
  final int daysElapsed;

  /// Total days in the month
  final int daysInMonth;

  /// Spending pace status (onTrack, faster, slower)
  final SpendingPaceStatus status;

  /// How much faster/slower as a percentage (e.g., 23 for 23% faster)
  final double percentageDiff;

  const SpendingPace({
    required this.currentTotal,
    required this.projectedTotal,
    required this.averageMonthlyTotal,
    required this.monthsInAverage,
    required this.dailyAverage,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.status,
    required this.percentageDiff,
  });
}

/// Represents spending total for a single week
class WeeklyTotal {
  final DateTime weekStart;
  final double total;

  const WeeklyTotal({
    required this.weekStart,
    required this.total,
  });
}

/// Represents spending total for a single month
class MonthlyTotal {
  final int year;
  final int month;
  final double total;

  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.total,
  });
}

/// Holds pre-computed summary data for a month.
/// Used for efficient single-pass data retrieval.
class MonthSummary {
  final List<Expense> expenses;
  final double total;
  final Map<ExpenseCategory, double> breakdown;

  const MonthSummary({
    required this.expenses,
    required this.total,
    required this.breakdown,
  });
}

/// Service class for managing expense data with Hive local storage.
///
/// This service provides CRUD operations for expenses and utility methods
/// for calculating totals and filtering by date/category.
class ExpenseService {
  static const String _boxName = 'expenses';
  static const Uuid _uuid = Uuid();

  late Box<Expense> _expenseBox;

  BudgetService? _budgetService;
  NotificationService? _notificationService;

  /// Set services for budget notifications (called from main.dart after init)
  void setBudgetServices(
      BudgetService budgetService, NotificationService notificationService) {
    _budgetService = budgetService;
    _notificationService = notificationService;
  }

  /// Initializes Hive and opens the expenses box.
  /// Must be called before any other operations.
  Future<void> init() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register adapters for our custom types
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExpenseSourceAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExpenseCategoryAdapter());
    }

    // Open the expenses box with aggressive compaction for better performance
    // Compacts when deleted entries exceed 20% of total
    _expenseBox = await Hive.openBox<Expense>(
      _boxName,
      compactionStrategy: (entries, deletedEntries) =>
          deletedEntries > entries * 0.2,
    );
  }

  /// Generates a new unique ID for an expense.
  String generateId() => _uuid.v4();

  /// Check budgets and send notifications if thresholds crossed
  Future<void> _checkBudgetNotifications(Expense expense) async {
    if (_budgetService == null || _notificationService == null) return;

    final year = expense.date.year;
    final month = expense.date.month;

    // Get all budgets for this month
    final budgets = _budgetService!.getAllBudgetsForMonth(year, month);
    if (budgets.isEmpty) return;

    // Calculate spending (single-pass for efficiency)
    final summary = getMonthSummary(year, month);
    final totalSpending = summary.total;
    final categorySpending = summary.breakdown;

    for (final budget in budgets) {
      final spent = budget.isOverallBudget
          ? totalSpending
          : categorySpending[budget.category] ?? 0;

      final progress = _budgetService!.calculateProgress(budget, spent);

      // Check 100% threshold first (exceeded)
      if (progress.status == BudgetStatus.exceeded && !budget.exceeded100Sent) {
        final label =
            budget.isOverallBudget ? 'Monthly' : budget.category!.displayName;
        await _notificationService!.showBudgetExceeded(
          title: '$label Budget Exceeded',
          body:
              'You\'ve spent ${CurrencyFormatter.format(spent)} of your ${CurrencyFormatter.format(budget.amount)} budget',
          notificationId: _notificationService!
              .getNotificationId(budget.id, isWarning: false),
        );
        await _budgetService!.markExceededSent(budget);
      }
      // Check 80% threshold (warning)
      else if (progress.status == BudgetStatus.warning &&
          !budget.warning80Sent) {
        final label =
            budget.isOverallBudget ? 'Monthly' : budget.category!.displayName;
        final percent = (progress.percentage * 100).toStringAsFixed(0);
        await _notificationService!.showBudgetWarning(
          title: '$label Budget Warning',
          body:
              'You\'ve used $percent% of your ${CurrencyFormatter.format(budget.amount)} budget',
          notificationId: _notificationService!
              .getNotificationId(budget.id, isWarning: true),
        );
        await _budgetService!.markWarningSent(budget);
      }
    }
  }

  /// Adds a new expense to storage.
  /// Returns the created expense.
  Future<Expense> addExpense({
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
    ExpenseSource source = ExpenseSource.manual,
    String? merchant,
    String? recurringExpenseId,
  }) async {
    final expense = Expense(
      id: generateId(),
      amount: amount,
      category: category,
      date: date,
      note: note,
      source: source,
      merchant: merchant,
      recurringExpenseId: recurringExpenseId,
    );

    await _expenseBox.put(expense.id, expense);

    // Check budget notifications
    await _checkBudgetNotifications(expense);

    return expense;
  }

  /// Updates an existing expense.
  /// Returns the updated expense.
  Future<Expense> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);

    // Check budget notifications
    await _checkBudgetNotifications(expense);

    return expense;
  }

  /// Deletes an expense by ID.
  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  /// Retrieves a single expense by ID.
  /// Returns null if not found.
  Expense? getExpense(String id) {
    return _expenseBox.get(id);
  }

  /// Retrieves all expenses, sorted by date (newest first).
  List<Expense> getAllExpenses() {
    final expenses = _expenseBox.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Retrieves expenses for a specific month and year.
  /// Optimized: filters first, then sorts only the filtered subset.
  List<Expense> getExpensesForMonth(int year, int month) {
    final monthExpenses = _expenseBox.values.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
    monthExpenses.sort((a, b) => b.date.compareTo(a.date));
    return monthExpenses;
  }

  /// Retrieves expenses for a specific month with pagination.
  /// Returns expenses sorted by date (newest first).
  ///
  /// [limit] - Maximum number of expenses to return (default 50)
  /// [offset] - Number of expenses to skip
  List<Expense> getExpensesForMonthPaginated(
    int year,
    int month, {
    int limit = 50,
    int offset = 0,
  }) {
    final monthExpenses = <Expense>[];

    for (final expense in _expenseBox.values) {
      if (expense.date.year == year && expense.date.month == month) {
        monthExpenses.add(expense);
      }
    }

    // Sort by date descending
    monthExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Apply pagination
    if (offset >= monthExpenses.length) return [];
    final end = (offset + limit).clamp(0, monthExpenses.length);
    return monthExpenses.sublist(offset, end);
  }

  /// Returns the total count of expenses for a month (for pagination UI).
  int getExpenseCountForMonth(int year, int month) {
    int count = 0;
    for (final expense in _expenseBox.values) {
      if (expense.date.year == year && expense.date.month == month) {
        count++;
      }
    }
    return count;
  }

  /// Returns a complete month summary in a single pass.
  /// This is more efficient than calling getExpensesForMonth, calculateTotal,
  /// and getCategoryBreakdown separately.
  MonthSummary getMonthSummary(int year, int month) {
    final expenses = <Expense>[];
    double total = 0;
    final breakdown = <ExpenseCategory, double>{};

    // Single pass through the data
    for (final expense in _expenseBox.values) {
      if (expense.date.year == year && expense.date.month == month) {
        expenses.add(expense);
        total += expense.amount;
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.amount;
      }
    }

    // Sort expenses by date (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return MonthSummary(
      expenses: expenses,
      total: total,
      breakdown: breakdown,
    );
  }

  /// Calculates the total amount for a list of expenses.
  double calculateTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Calculates the total for the current month.
  double getCurrentMonthTotal() {
    final now = DateTime.now();
    return getMonthSummary(now.year, now.month).total;
  }

  /// Returns a map of category -> total amount for a list of expenses.
  Map<ExpenseCategory, double> getCategoryBreakdown(List<Expense> expenses) {
    final breakdown = <ExpenseCategory, double>{};

    for (final expense in expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }

    return breakdown;
  }

  /// Returns category breakdown for the current month.
  Map<ExpenseCategory, double> getCurrentMonthCategoryBreakdown() {
    final now = DateTime.now();
    return getMonthSummary(now.year, now.month).breakdown;
  }

  /// Returns spending pace analysis for a given month.
  /// Compares current spending rate against 3-month average to determine
  /// if user is spending faster or slower than usual.
  ///
  /// Returns null if there's insufficient historical data (needs at least 1 month).
  SpendingPace? getSpendingPace(int year, int month) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    // Calculate days in the requested month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Days elapsed (full month for past months, current day for current month)
    final daysElapsed = isCurrentMonth ? now.day : daysInMonth;

    // Get current month total
    final currentTotal = getMonthSummary(year, month).total;

    // Calculate 3-month average (excluding current month)
    // Get previous 3 months
    final monthsToAverage = <double>[];
    var checkYear = year;
    var checkMonth = month;

    for (var i = 0; i < 3; i++) {
      // Move to previous month
      checkMonth--;
      if (checkMonth <= 0) {
        checkMonth = 12;
        checkYear--;
      }

      final monthTotal = getMonthSummary(checkYear, checkMonth).total;
      if (monthTotal > 0) {
        monthsToAverage.add(monthTotal);
      }
    }

    // Need at least 1 month of historical data
    if (monthsToAverage.isEmpty) {
      return null;
    }

    // Calculate 3-month average (or however many months we have)
    final threeMonthAverage =
        monthsToAverage.reduce((a, b) => a + b) / monthsToAverage.length;

    // Calculate daily average for current period
    final dailyAverage = daysElapsed > 0 ? currentTotal / daysElapsed : 0.0;

    // Project total for end of month
    final projectedTotal = dailyAverage * daysInMonth;

    // Calculate percentage difference from 3-month average
    // Positive = spending faster, Negative = spending slower
    final percentageDiff =
        ((projectedTotal - threeMonthAverage) / threeMonthAverage) * 100;

    // Determine status based on percentage difference
    // Within 10% = on track
    // More than 10% higher = faster
    // More than 10% lower = slower
    final SpendingPaceStatus status;
    if (percentageDiff.abs() <= 10) {
      status = SpendingPaceStatus.onTrack;
    } else if (percentageDiff > 10) {
      status = SpendingPaceStatus.faster;
    } else {
      status = SpendingPaceStatus.slower;
    }

    return SpendingPace(
      currentTotal: currentTotal,
      projectedTotal: projectedTotal,
      averageMonthlyTotal: threeMonthAverage,
      monthsInAverage: monthsToAverage.length,
      dailyAverage: dailyAverage,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      status: status,
      percentageDiff: percentageDiff,
    );
  }

  /// Daily spending for a specific month (for line chart - daily mode).
  /// Returns map of day number (1-31) to total amount spent that day.
  /// Days with no expenses are not included in the map.
  Map<int, double> getDailySpending(int year, int month) {
    final dailyTotals = <int, double>{};

    // Single pass through expenses for the month
    for (final expense in _expenseBox.values) {
      if (expense.date.year == year && expense.date.month == month) {
        final day = expense.date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
      }
    }

    return dailyTotals;
  }

  /// Weekly spending totals for last N weeks (for line chart - weekly mode).
  /// Returns list of WeeklyTotal sorted by weekStart ascending.
  /// Each week starts on Monday.
  /// Always returns exactly N weeks, with 0 total for weeks with no expenses.
  List<WeeklyTotal> getWeeklySpending(int weeks) {
    // Guard clause for invalid input
    if (weeks <= 0) return [];

    final now = DateTime.now();
    // Calculate the start of the current week (Monday)
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfCurrentWeek = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );

    // Calculate the start date (N weeks back from current week start)
    final startDate =
        startOfCurrentWeek.subtract(Duration(days: (weeks - 1) * 7));

    // Pre-populate all N weeks with 0 total
    final weeklyTotals = <DateTime, double>{};
    for (var i = 0; i < weeks; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      weeklyTotals[weekStart] = 0;
    }

    // Single pass through expenses in range
    for (final expense in _expenseBox.values) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      // Check if expense is within our date range
      if (expenseDate.isBefore(startDate) || expenseDate.isAfter(now)) {
        continue;
      }

      // Calculate the Monday of the expense's week
      final weekStart = expenseDate.subtract(
        Duration(days: expenseDate.weekday - 1),
      );
      final normalizedWeekStart = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      weeklyTotals[normalizedWeekStart] =
          (weeklyTotals[normalizedWeekStart] ?? 0) + expense.amount;
    }

    // Convert to list of WeeklyTotal and sort ascending
    final result = weeklyTotals.entries
        .map((e) => WeeklyTotal(weekStart: e.key, total: e.value))
        .toList();
    result.sort((a, b) => a.weekStart.compareTo(b.weekStart));

    return result;
  }

  /// Monthly spending totals for last N months (for line chart monthly mode + bar chart).
  /// Returns list of MonthlyTotal sorted by date ascending (oldest first).
  /// Always returns exactly N months, with 0 total for months with no expenses.
  List<MonthlyTotal> getMonthlyTotals(int months) {
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

    // Single pass through expenses in range
    for (final expense in _expenseBox.values) {
      final expYear = expense.date.year;
      final expMonth = expense.date.month;

      // Check if expense is within our date range
      final isAfterOrEqualStart = expYear > startYear ||
          (expYear == startYear && expMonth >= startMonth);
      final isBeforeOrEqualEnd =
          expYear < now.year || (expYear == now.year && expMonth <= now.month);

      if (!isAfterOrEqualStart || !isBeforeOrEqualEnd) {
        continue;
      }

      final key = '$expYear-$expMonth';
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + expense.amount;
    }

    // Convert to list of MonthlyTotal and sort ascending
    final result = monthlyTotals.entries.map((e) {
      final parts = e.key.split('-');
      return MonthlyTotal(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        total: e.value,
      );
    }).toList();

    // Sort by year then month (ascending)
    result.sort((a, b) {
      final yearCompare = a.year.compareTo(b.year);
      if (yearCompare != 0) return yearCompare;
      return a.month.compareTo(b.month);
    });

    return result;
  }

  /// Category breakdown for arbitrary date range (for analytics donut).
  /// Returns map of category to total amount.
  Map<ExpenseCategory, double> getCategoryBreakdownForRange(
    DateTime start,
    DateTime end,
  ) {
    final breakdown = <ExpenseCategory, double>{};

    // Normalize to start of day for consistent comparison
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    // Single pass through expenses in range
    for (final expense in _expenseBox.values) {
      if (expense.date.isBefore(startDate) || expense.date.isAfter(endDate)) {
        continue;
      }

      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }

    return breakdown;
  }

  /// Returns the listenable box for reactive UI updates.
  /// Use this with ValueListenableBuilder to rebuild UI on data changes.
  Box<Expense> get box => _expenseBox;

  /// Clears all expenses (use with caution!).
  Future<void> clearAll() async {
    await _expenseBox.clear();
  }

  /// Returns the count of all expenses.
  int get count => _expenseBox.length;

  /// Checks if there are any expenses.
  bool get isEmpty => _expenseBox.isEmpty;

  /// Checks if there are expenses.
  bool get isNotEmpty => _expenseBox.isNotEmpty;

  /// Returns frequent expense templates based on recent spending patterns.
  ///
  /// Analyzes the last [daysToAnalyze] days (default 30) or last [maxExpenses]
  /// expenses (default 50), whichever gives more data. Groups by merchant+category
  /// combination and returns the most frequent patterns.
  ///
  /// [limit] - Maximum number of templates to return (default 3)
  /// [daysToAnalyze] - Number of days to look back (default 30)
  /// [maxExpenses] - Maximum number of recent expenses to analyze (default 50)
  List<ExpenseTemplate> getFrequentTemplates({
    int limit = 3,
    int daysToAnalyze = 30,
    int maxExpenses = 50,
  }) {
    if (_expenseBox.isEmpty) return [];

    // Get all expenses sorted by date (newest first)
    final allExpenses = _expenseBox.values.toList();
    allExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Calculate cutoff date
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToAnalyze));

    // Filter to recent expenses (within date range or within maxExpenses count)
    final recentExpenses = <Expense>[];
    for (var i = 0; i < allExpenses.length && i < maxExpenses; i++) {
      final expense = allExpenses[i];
      // Include if within date range OR within max count
      if (expense.date.isAfter(cutoffDate) ||
          recentExpenses.length < maxExpenses) {
        recentExpenses.add(expense);
      }
    }

    if (recentExpenses.isEmpty) return [];

    // Group by merchant+category combination
    // Key: "merchant|categoryIndex" or "null|categoryIndex" for no merchant
    final groups = <String, List<Expense>>{};

    for (final expense in recentExpenses) {
      final merchantKey = expense.merchant?.toLowerCase().trim() ?? '';
      final key = '$merchantKey|${expense.category.index}';
      groups.putIfAbsent(key, () => []).add(expense);
    }

    // Convert groups to templates with usage count and average amount
    final templates = <ExpenseTemplate>[];

    for (final entry in groups.entries) {
      final expenses = entry.value;
      final keyParts = entry.key.split('|');
      final merchantKey = keyParts[0];
      final categoryIndex = int.parse(keyParts[1]);

      // Calculate average amount
      final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final averageAmount = totalAmount / expenses.length;

      // Get the most common merchant name formatting (preserve original case)
      String? merchant;
      if (merchantKey.isNotEmpty) {
        // Use the most recent expense's merchant formatting
        merchant = expenses.first.merchant;
      }

      templates.add(ExpenseTemplate(
        merchant: merchant,
        amount: averageAmount,
        category: ExpenseCategory.values[categoryIndex],
        usageCount: expenses.length,
      ));
    }

    // Sort by usage count (most frequent first)
    templates.sort((a, b) => b.usageCount.compareTo(a.usageCount));

    // Return top templates
    return templates.take(limit).toList();
  }
}
