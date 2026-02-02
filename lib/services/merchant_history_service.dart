import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/merchant_history.dart';

/// Service for managing merchant history and providing autocomplete suggestions.
///
/// Features:
/// - Stores merchant names with usage count and last used date
/// - Provides fuzzy matching suggestions as user types
/// - Returns recent and frequently used merchants
/// - Tracks category usage per merchant for smart auto-mapping
/// - Suggests categories based on learned merchant preferences
class MerchantHistoryService {
  static const String _boxName = 'merchant_history';

  /// Threshold for how many times a category must be used before
  /// it becomes the default suggestion for a merchant.
  static const int categoryThreshold = 3;

  late Box<MerchantHistory> _box;

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Initialize the service and open the Hive box.
  /// Must be called before using any other methods.
  Future<void> init() async {
    if (_initialized) return;

    _box = await Hive.openBox<MerchantHistory>(_boxName);
    _initialized = true;
  }

  /// Get the Hive box for direct access if needed.
  Box<MerchantHistory> get box {
    _ensureInitialized();
    return _box;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'MerchantHistoryService not initialized. Call init() first.',
      );
    }
  }

  /// Get merchant suggestions based on a query string.
  ///
  /// Uses fuzzy matching - returns merchants that contain the query
  /// as a substring (case-insensitive).
  ///
  /// Results are sorted by:
  /// 1. Exact prefix match first (merchants starting with query)
  /// 2. Then by usage count (most used first)
  ///
  /// [query] - The search string
  /// [limit] - Maximum number of suggestions to return (default 5)
  List<String> getSuggestions(String query, {int limit = 5}) {
    _ensureInitialized();

    if (query.isEmpty) {
      return getRecentMerchants(limit: limit);
    }

    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return getRecentMerchants(limit: limit);
    }

    final matches = <MerchantHistory>[];

    for (final merchant in _box.values) {
      final lowerName = merchant.name.toLowerCase();
      if (lowerName.contains(lowerQuery)) {
        matches.add(merchant);
      }
    }

    // Sort: prefix matches first, then by usage count
    matches.sort((a, b) {
      final aLower = a.name.toLowerCase();
      final bLower = b.name.toLowerCase();
      final aStartsWith = aLower.startsWith(lowerQuery);
      final bStartsWith = bLower.startsWith(lowerQuery);

      // Prefix matches come first
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Then sort by usage count (descending)
      return b.usageCount.compareTo(a.usageCount);
    });

    return matches.take(limit).map((m) => m.name).toList();
  }

  /// Record a merchant usage.
  ///
  /// If the merchant already exists, increments its usage count
  /// and updates the last used timestamp.
  /// If it doesn't exist, creates a new entry.
  ///
  /// [merchant] - The merchant name to record
  Future<void> recordMerchant(String merchant) async {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return;

    // Normalize to consistent casing for storage key
    // but preserve original casing for display
    final key = trimmed.toLowerCase();

    final existing = _box.get(key);
    if (existing != null) {
      existing.recordUsage();
      await existing.save();
    } else {
      final newMerchant = MerchantHistory(name: trimmed);
      await _box.put(key, newMerchant);
    }
  }

  /// Get the most recently used merchants.
  ///
  /// [limit] - Maximum number of merchants to return (default 5)
  List<String> getRecentMerchants({int limit = 5}) {
    _ensureInitialized();

    final merchants = _box.values.toList();
    merchants.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    return merchants.take(limit).map((m) => m.name).toList();
  }

  /// Get the most frequently used merchants.
  ///
  /// [limit] - Maximum number of merchants to return (default 5)
  List<String> getFrequentMerchants({int limit = 5}) {
    _ensureInitialized();

    final merchants = _box.values.toList();
    merchants.sort((a, b) => b.usageCount.compareTo(a.usageCount));

    return merchants.take(limit).map((m) => m.name).toList();
  }

  /// Get all merchants (for debugging/export).
  List<MerchantHistory> getAll() {
    _ensureInitialized();
    return _box.values.toList();
  }

  /// Clear all merchant history.
  Future<void> clearAll() async {
    _ensureInitialized();
    await _box.clear();
  }

  /// Number of stored merchants.
  int get count {
    _ensureInitialized();
    return _box.length;
  }

  // ========== Category Auto-Mapping Methods ==========

  /// Gets the suggested category for a merchant based on usage history.
  ///
  /// Returns the default category if one has been set (after reaching threshold),
  /// otherwise returns null.
  ///
  /// [merchant] - The merchant name to look up (case-insensitive)
  ExpenseCategory? getSuggestedCategory(String merchant) {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return null;

    final key = trimmed.toLowerCase();
    final history = _box.get(key);

    return history?.defaultCategory;
  }

  /// Gets the most used category for a merchant, even if it hasn't reached threshold.
  ///
  /// Useful for showing what category the user typically uses, even before
  /// it becomes the automatic default.
  ///
  /// [merchant] - The merchant name to look up (case-insensitive)
  ExpenseCategory? getMostUsedCategory(String merchant) {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return null;

    final key = trimmed.toLowerCase();
    final history = _box.get(key);

    return history?.mostUsedCategory;
  }

  /// Records a category usage for a merchant.
  ///
  /// This should be called when saving an expense to learn the user's
  /// category preferences for each merchant. After [categoryThreshold] uses
  /// of the same category, it becomes the default suggestion.
  ///
  /// [merchant] - The merchant name
  /// [category] - The category used for this expense
  Future<void> recordMerchantCategory(
    String merchant,
    ExpenseCategory category,
  ) async {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return;

    final key = trimmed.toLowerCase();
    final existing = _box.get(key);

    if (existing != null) {
      existing.recordCategoryUsage(category, threshold: categoryThreshold);
      await existing.save();
    } else {
      // Create new merchant history with category
      final newMerchant = MerchantHistory(name: trimmed);
      newMerchant.recordCategoryUsage(category, threshold: categoryThreshold);
      await _box.put(key, newMerchant);
    }
  }

  /// Records both merchant usage and category in a single call.
  ///
  /// Convenience method that combines [recordMerchant] and [recordMerchantCategory].
  /// Use this when saving an expense to update all merchant statistics at once.
  ///
  /// [merchant] - The merchant name
  /// [category] - The category used for this expense
  Future<void> recordMerchantWithCategory(
    String merchant,
    ExpenseCategory category,
  ) async {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return;

    final key = trimmed.toLowerCase();
    final existing = _box.get(key);

    if (existing != null) {
      existing.recordUsage();
      existing.recordCategoryUsage(category, threshold: categoryThreshold);
      await existing.save();
    } else {
      final newMerchant = MerchantHistory(name: trimmed);
      newMerchant.recordCategoryUsage(category, threshold: categoryThreshold);
      await _box.put(key, newMerchant);
    }
  }

  /// Gets the category usage stats for a merchant.
  ///
  /// Returns a map of category names to usage counts, or null if merchant not found.
  /// Useful for debugging or displaying category history to the user.
  ///
  /// [merchant] - The merchant name to look up (case-insensitive)
  Map<String, int>? getCategoryUsage(String merchant) {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return null;

    final key = trimmed.toLowerCase();
    final history = _box.get(key);

    return history?.categoryUsage;
  }

  /// Checks if a merchant has a default category set.
  ///
  /// [merchant] - The merchant name to look up (case-insensitive)
  bool hasDefaultCategory(String merchant) {
    _ensureInitialized();

    final trimmed = merchant.trim();
    if (trimmed.isEmpty) return false;

    final key = trimmed.toLowerCase();
    final history = _box.get(key);

    return history?.defaultCategory != null;
  }
}
