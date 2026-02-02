import 'package:hive/hive.dart';
import 'expense.dart';

part 'merchant_history.g.dart';

/// Model for tracking merchant usage history.
///
/// Stores the merchant name along with usage statistics:
/// - [usageCount]: How many times this merchant has been used
/// - [lastUsed]: When this merchant was last used
/// - [categoryUsage]: Map of category names to usage counts
/// - [defaultCategory]: The most commonly used category for this merchant (set after threshold)
///
/// Used by MerchantHistoryService to provide autocomplete suggestions
/// and smart category auto-mapping.
@HiveType(typeId: 14)
class MerchantHistory extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  int usageCount;

  @HiveField(2)
  DateTime lastUsed;

  /// Tracks how many times each category has been used with this merchant.
  /// Key is the category name (ExpenseCategory.name), value is the count.
  @HiveField(3)
  Map<String, int> categoryUsage;

  /// The default category to suggest for this merchant.
  /// Set when a category has been used at least [categoryThreshold] times.
  /// Stored as the ExpenseCategory name (e.g., 'food', 'transport').
  @HiveField(4)
  String? defaultCategoryName;

  MerchantHistory({
    required this.name,
    this.usageCount = 1,
    DateTime? lastUsed,
    Map<String, int>? categoryUsage,
    this.defaultCategoryName,
  })  : lastUsed = lastUsed ?? DateTime.now(),
        categoryUsage = categoryUsage ?? {};

  /// Gets the default category as an ExpenseCategory enum.
  /// Returns null if no default is set or if the stored name is invalid.
  ExpenseCategory? get defaultCategory {
    if (defaultCategoryName == null) return null;
    try {
      return ExpenseCategory.values.firstWhere(
        (c) => c.name == defaultCategoryName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sets the default category from an ExpenseCategory enum.
  set defaultCategory(ExpenseCategory? category) {
    defaultCategoryName = category?.name;
  }

  /// Increment usage count and update last used timestamp.
  void recordUsage() {
    usageCount++;
    lastUsed = DateTime.now();
  }

  /// Records a category usage for this merchant.
  ///
  /// Increments the usage count for the given category.
  /// If the category reaches the threshold, it becomes the default.
  ///
  /// [category] - The category used with this merchant
  /// [threshold] - Number of uses before a category becomes default (default: 3)
  void recordCategoryUsage(ExpenseCategory category, {int threshold = 3}) {
    final categoryName = category.name;
    categoryUsage[categoryName] = (categoryUsage[categoryName] ?? 0) + 1;

    // Update default if this category has reached the threshold
    // and either no default exists or this category has more usage
    final currentCount = categoryUsage[categoryName]!;
    if (currentCount >= threshold) {
      if (defaultCategoryName == null) {
        defaultCategoryName = categoryName;
      } else {
        // Check if this category now has more usage than the current default
        final defaultCount = categoryUsage[defaultCategoryName] ?? 0;
        if (currentCount > defaultCount) {
          defaultCategoryName = categoryName;
        }
      }
    }
  }

  /// Gets the most used category for this merchant, regardless of threshold.
  /// Returns null if no categories have been recorded.
  ExpenseCategory? get mostUsedCategory {
    if (categoryUsage.isEmpty) return null;

    String? maxCategoryName;
    int maxCount = 0;

    for (final entry in categoryUsage.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxCategoryName = entry.key;
      }
    }

    if (maxCategoryName == null) return null;

    try {
      return ExpenseCategory.values.firstWhere(
        (c) => c.name == maxCategoryName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Gets the usage count for a specific category.
  int getCategoryCount(ExpenseCategory category) {
    return categoryUsage[category.name] ?? 0;
  }

  @override
  String toString() {
    return 'MerchantHistory(name: $name, usageCount: $usageCount, '
        'lastUsed: $lastUsed, defaultCategory: $defaultCategoryName, '
        'categoryUsage: $categoryUsage)';
  }
}
