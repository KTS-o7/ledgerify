import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

/// Service for providing smart category defaults based on time and usage patterns.
///
/// Suggests categories based on:
/// 1. Time of day (meal times default to food)
/// 2. Day of week (weekends default to entertainment)
/// 3. Last used category (for quick repeat entries)
/// 4. Most frequent category (fallback)
class CategoryDefaultService {
  static const String _boxName = 'category_defaults';
  static const String _lastCategoryKey = 'last_expense_category';

  late Box<String> _box;

  /// Initializes the service by opening the Hive box.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Returns the last used category, or null if none.
  ExpenseCategory? getLastUsedCategory() {
    final categoryName = _box.get(_lastCategoryKey);
    if (categoryName == null) return null;

    // Find matching enum value by name
    try {
      return ExpenseCategory.values.firstWhere(
        (c) => c.name == categoryName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves the last used category.
  Future<void> setLastUsedCategory(ExpenseCategory category) async {
    await _box.put(_lastCategoryKey, category.name);
  }

  /// Returns a smart category suggestion based on current time and usage.
  ///
  /// Priority:
  /// 1. Meal times (7-10am, 12-2pm, 7-9pm) -> food
  /// 2. Weekends (Sat/Sun) -> entertainment
  /// 3. Last used category (if available)
  /// 4. Most frequent category (if provided)
  /// 5. Default to food
  ExpenseCategory getSuggestedCategory({
    Map<ExpenseCategory, int>? categoryFrequencies,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final hour = currentTime.hour;
    final weekday = currentTime.weekday;

    // Check meal times first - these are strong signals
    // Breakfast: 7am-10am
    if (hour >= 7 && hour < 10) {
      return ExpenseCategory.food;
    }

    // Lunch: 12pm-2pm
    if (hour >= 12 && hour < 14) {
      return ExpenseCategory.food;
    }

    // Dinner: 7pm-9pm
    if (hour >= 19 && hour < 21) {
      return ExpenseCategory.food;
    }

    // Weekends (Saturday=6, Sunday=7) suggest entertainment
    final isWeekend =
        weekday == DateTime.saturday || weekday == DateTime.sunday;
    if (isWeekend) {
      return ExpenseCategory.entertainment;
    }

    // Try last used category
    final lastUsed = getLastUsedCategory();
    if (lastUsed != null) {
      return lastUsed;
    }

    // Try most frequent category
    if (categoryFrequencies != null && categoryFrequencies.isNotEmpty) {
      final mostFrequent = _getMostFrequentCategory(categoryFrequencies);
      if (mostFrequent != null) {
        return mostFrequent;
      }
    }

    // Default fallback
    return ExpenseCategory.food;
  }

  /// Finds the most frequent category from frequency map.
  ExpenseCategory? _getMostFrequentCategory(
    Map<ExpenseCategory, int> frequencies,
  ) {
    if (frequencies.isEmpty) return null;

    ExpenseCategory? mostFrequent;
    int maxCount = 0;

    for (final entry in frequencies.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostFrequent = entry.key;
      }
    }

    return mostFrequent;
  }
}
