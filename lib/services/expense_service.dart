import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';
import 'budget_service.dart';
import 'notification_service.dart';

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

    // Open the expenses box
    _expenseBox = await Hive.openBox<Expense>(_boxName);
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
  }) async {
    final expense = Expense(
      id: generateId(),
      amount: amount,
      category: category,
      date: date,
      note: note,
      source: source,
      merchant: merchant,
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
}
