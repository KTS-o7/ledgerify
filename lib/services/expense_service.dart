import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

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
    return expense;
  }

  /// Updates an existing expense.
  /// Returns the updated expense.
  Future<Expense> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
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
