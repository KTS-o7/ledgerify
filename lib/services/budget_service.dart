import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';

/// Service class for managing budgets with Hive local storage.
///
/// This service provides CRUD operations for budgets and utility methods
/// for calculating budget progress and managing notification flags.
///
/// Uses composite keys for O(1) budget lookups by year/month/category.
class BudgetService {
  static const String _boxName = 'budgets';
  static const Uuid _uuid = Uuid();

  late Box<Budget> _budgetBox;

  /// Generates a composite key for budget lookup.
  /// Format: "year_month_category" or "year_month_overall"
  String _getBudgetKey(int year, int month, {ExpenseCategory? category}) {
    if (category != null) {
      return '${year}_${month}_${category.name}';
    }
    return '${year}_${month}_overall';
  }

  /// Returns the listenable box for reactive UI updates.
  Box<Budget> get box => _budgetBox;

  /// Initialize Hive box
  Future<void> init() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(BudgetAdapter());
    }

    // Open the budgets box
    _budgetBox = await Hive.openBox<Budget>(_boxName);
  }

  /// Generates a new unique ID for a budget.
  String generateId() => _uuid.v4();

  /// Set or update a budget for a category (or overall if category is null)
  ///
  /// If a budget already exists for the given category/month/year combination,
  /// it will be updated. Otherwise, a new budget will be created.
  ///
  /// Uses composite key for O(1) lookup and storage.
  Future<Budget> setBudget({
    ExpenseCategory? category,
    required double amount,
    required int year,
    required int month,
  }) async {
    final key = _getBudgetKey(year, month, category: category);

    // Check if a budget already exists using direct O(1) lookup
    final existing = _budgetBox.get(key);

    if (existing != null) {
      // Update existing budget
      final updated = existing.copyWith(
        amount: amount,
        warning80Sent: false, // Reset notification flags when amount changes
        exceeded100Sent: false,
      );
      await _budgetBox.put(key, updated);
      return updated;
    }

    // Create new budget
    final budget = Budget(
      id: generateId(),
      category: category,
      amount: amount,
      year: year,
      month: month,
    );

    await _budgetBox.put(key, budget);
    return budget;
  }

  /// Delete a budget by its composite key components
  ///
  /// For backwards compatibility, also accepts the budget's internal id,
  /// but composite key lookup is preferred for O(1) performance.
  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  /// Delete a budget using year, month, and optional category
  ///
  /// Uses composite key for O(1) deletion.
  Future<void> deleteBudgetByKey({
    required int year,
    required int month,
    ExpenseCategory? category,
  }) async {
    final key = _getBudgetKey(year, month, category: category);
    await _budgetBox.delete(key);
  }

  /// Get overall budget for a month
  ///
  /// Uses composite key for O(1) lookup.
  Budget? getOverallBudget(int year, int month) {
    final key = _getBudgetKey(year, month);
    return _budgetBox.get(key);
  }

  /// Get category budget for a month
  ///
  /// Uses composite key for O(1) lookup.
  Budget? getCategoryBudget(ExpenseCategory category, int year, int month) {
    final key = _getBudgetKey(year, month, category: category);
    return _budgetBox.get(key);
  }

  /// Get all budgets for a month
  ///
  /// This method still requires iteration since we need all budgets
  /// matching the year/month. However, it's less frequently called
  /// than individual budget lookups.
  List<Budget> getAllBudgetsForMonth(int year, int month) {
    final budgets = <Budget>[];

    // Check for overall budget using O(1) lookup
    final overallKey = _getBudgetKey(year, month);
    final overall = _budgetBox.get(overallKey);
    if (overall != null) {
      budgets.add(overall);
    }

    // Check for each category budget using O(1) lookups
    for (final category in ExpenseCategory.values) {
      final categoryKey = _getBudgetKey(year, month, category: category);
      final categoryBudget = _budgetBox.get(categoryKey);
      if (categoryBudget != null) {
        budgets.add(categoryBudget);
      }
    }

    // Sort: overall budget first, then by category name
    budgets.sort((a, b) {
      if (a.isOverallBudget && !b.isOverallBudget) return -1;
      if (!a.isOverallBudget && b.isOverallBudget) return 1;
      if (a.category != null && b.category != null) {
        return a.category!.displayName.compareTo(b.category!.displayName);
      }
      return 0;
    });
    return budgets;
  }

  /// Calculate budget progress
  ///
  /// Returns a [BudgetProgress] object containing the budget, spent amount,
  /// percentage, and status (ok, warning, or exceeded).
  BudgetProgress calculateProgress(Budget budget, double spent) {
    final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
    final status = percentage >= 1.0
        ? BudgetStatus.exceeded
        : percentage >= 0.8
            ? BudgetStatus.warning
            : BudgetStatus.ok;
    return BudgetProgress(
      budget: budget,
      spent: spent,
      percentage: percentage,
      status: status,
    );
  }

  /// Reset notification flags (called when budget is modified)
  ///
  /// Uses composite key for storage.
  Future<void> resetNotificationFlags(Budget budget) async {
    final key =
        _getBudgetKey(budget.year, budget.month, category: budget.category);
    final updated = budget.copyWith(
      warning80Sent: false,
      exceeded100Sent: false,
    );
    await _budgetBox.put(key, updated);
  }

  /// Mark warning notification as sent
  ///
  /// Uses composite key for storage.
  Future<void> markWarningSent(Budget budget) async {
    final key =
        _getBudgetKey(budget.year, budget.month, category: budget.category);
    budget.warning80Sent = true;
    await _budgetBox.put(key, budget);
  }

  /// Mark exceeded notification as sent
  ///
  /// Uses composite key for storage.
  Future<void> markExceededSent(Budget budget) async {
    final key =
        _getBudgetKey(budget.year, budget.month, category: budget.category);
    budget.exceeded100Sent = true;
    await _budgetBox.put(key, budget);
  }

  /// Get a budget by its key (either composite key or internal id)
  ///
  /// Prefer using [getOverallBudget] or [getCategoryBudget] for O(1) lookups.
  Budget? getBudget(String key) {
    return _budgetBox.get(key);
  }

  /// Get a budget using year, month, and optional category
  ///
  /// Uses composite key for O(1) lookup.
  Budget? getBudgetByKey({
    required int year,
    required int month,
    ExpenseCategory? category,
  }) {
    final key = _getBudgetKey(year, month, category: category);
    return _budgetBox.get(key);
  }

  /// Get all budgets
  List<Budget> getAllBudgets() {
    final budgets = _budgetBox.values.toList();
    // Sort by year (desc), month (desc), then category
    budgets.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      final monthCompare = b.month.compareTo(a.month);
      if (monthCompare != 0) return monthCompare;
      if (a.isOverallBudget && !b.isOverallBudget) return -1;
      if (!a.isOverallBudget && b.isOverallBudget) return 1;
      return 0;
    });
    return budgets;
  }

  /// Clears all budgets (use with caution!)
  Future<void> clearAll() async {
    await _budgetBox.clear();
  }

  /// Returns the count of all budgets
  int get count => _budgetBox.length;

  /// Checks if there are any budgets
  bool get isEmpty => _budgetBox.isEmpty;

  /// Checks if there are budgets
  bool get isNotEmpty => _budgetBox.isNotEmpty;
}
