import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';

/// Service class for managing budgets with Hive local storage.
///
/// This service provides CRUD operations for budgets and utility methods
/// for calculating budget progress and managing notification flags.
class BudgetService {
  static const String _boxName = 'budgets';
  static const Uuid _uuid = Uuid();

  late Box<Budget> _budgetBox;

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
  Future<Budget> setBudget({
    ExpenseCategory? category,
    required double amount,
    required int year,
    required int month,
  }) async {
    // Check if a budget already exists for this category/month/year
    final existing = category == null
        ? getOverallBudget(year, month)
        : getCategoryBudget(category, year, month);

    if (existing != null) {
      // Update existing budget
      final updated = existing.copyWith(
        amount: amount,
        warning80Sent: false, // Reset notification flags when amount changes
        exceeded100Sent: false,
      );
      await _budgetBox.put(updated.id, updated);
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

    await _budgetBox.put(budget.id, budget);
    return budget;
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  /// Get overall budget for a month
  Budget? getOverallBudget(int year, int month) {
    for (final budget in _budgetBox.values) {
      if (budget.isOverallBudget &&
          budget.year == year &&
          budget.month == month) {
        return budget;
      }
    }
    return null;
  }

  /// Get category budget for a month
  Budget? getCategoryBudget(ExpenseCategory category, int year, int month) {
    for (final budget in _budgetBox.values) {
      if (budget.category == category &&
          budget.year == year &&
          budget.month == month) {
        return budget;
      }
    }
    return null;
  }

  /// Get all budgets for a month
  List<Budget> getAllBudgetsForMonth(int year, int month) {
    final budgets = <Budget>[];
    for (final budget in _budgetBox.values) {
      if (budget.year == year && budget.month == month) {
        budgets.add(budget);
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
  Future<void> resetNotificationFlags(Budget budget) async {
    final updated = budget.copyWith(
      warning80Sent: false,
      exceeded100Sent: false,
    );
    await _budgetBox.put(updated.id, updated);
  }

  /// Mark warning notification as sent
  Future<void> markWarningSent(Budget budget) async {
    budget.warning80Sent = true;
    await budget.save();
  }

  /// Mark exceeded notification as sent
  Future<void> markExceededSent(Budget budget) async {
    budget.exceeded100Sent = true;
    await budget.save();
  }

  /// Get a budget by ID
  Budget? getBudget(String id) {
    return _budgetBox.get(id);
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
