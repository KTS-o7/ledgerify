import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/widget_config.dart';
import '../utils/currency_formatter.dart';
import 'budget_service.dart';
import 'expense_service.dart';
import 'recurring_expense_service.dart';
import 'recurring_income_service.dart';

/// Context type for adaptive widget messaging
enum WidgetContextType {
  normal,
  warning,
  urgent,
  morning,
  evening,
  upcoming,
}

/// Holds contextual widget information
class WidgetContext {
  final WidgetContextType type;
  final String statusText;
  final String alertText;
  final String? alertIcon;

  const WidgetContext({
    required this.type,
    required this.statusText,
    required this.alertText,
    this.alertIcon,
  });
}

/// Service for managing home screen widget data synchronization.
///
/// Handles:
/// - Syncing expense/budget data to SharedPreferences for native widget
/// - Auto-learning top categories from spending history
/// - Context-aware messaging (time of day, budget status, upcoming items)
/// - Theme synchronization (dark/light mode)
class WidgetService {
  static const String _boxName = 'widget_config';
  static const String _androidWidgetName = 'LedgerifyWidgetProvider';
  static const String _appGroupId = 'group.com.ledgerify.widget';

  late Box<WidgetConfig> _configBox;

  // Service references
  ExpenseService? _expenseService;
  BudgetService? _budgetService;
  RecurringExpenseService? _recurringExpenseService;
  RecurringIncomeService? _recurringIncomeService;

  // Debounce timer to prevent excessive syncs
  Timer? _syncDebounceTimer;
  static const Duration _syncDebounceDelay = Duration(milliseconds: 500);

  // Cache for auto-learned categories (avoid recalculating every sync)
  List<ExpenseCategory>? _cachedCategories;
  DateTime? _categoriesCacheTime;
  static const Duration _categoriesCacheDuration = Duration(minutes: 5);

  /// Initialize the widget service.
  /// Must be called after Hive is initialized.
  Future<void> init() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(WidgetConfigAdapter());
    }

    // Open the config box
    _configBox = await Hive.openBox<WidgetConfig>(_boxName);

    // Ensure a default config exists
    if (_configBox.get('default') == null) {
      await _configBox.put('default', WidgetConfig());
    }

    // Set app group for iOS (not used for Android-only, but good practice)
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Set service references for data access.
  /// Should be called from main.dart after all services are initialized.
  void setServices({
    required ExpenseService expenseService,
    required BudgetService budgetService,
    required RecurringExpenseService recurringExpenseService,
    required RecurringIncomeService recurringIncomeService,
  }) {
    _expenseService = expenseService;
    _budgetService = budgetService;
    _recurringExpenseService = recurringExpenseService;
    _recurringIncomeService = recurringIncomeService;
  }

  /// Get the current widget configuration.
  WidgetConfig get config => _configBox.get('default') ?? WidgetConfig();

  /// Update widget configuration.
  Future<void> updateConfig(WidgetConfig newConfig) async {
    await _configBox.put('default', newConfig);
    await syncData();
  }

  /// Update the widget update frequency.
  Future<void> setUpdateFrequency(WidgetUpdateFrequency frequency) async {
    final newConfig = config.copyWith(
      updateFrequencyMinutes: frequency.minutes,
    );
    await updateConfig(newConfig);
  }

  /// Sync data if due based on update frequency.
  /// Returns true if sync was performed, false otherwise.
  Future<bool> syncIfDue({bool isDarkMode = true}) async {
    if (!config.shouldSync()) return false;
    await syncDataImmediate(isDarkMode: isDarkMode);
    return true;
  }

  /// Get quick-add categories (user-configured or auto-learned with caching).
  List<ExpenseCategory> getQuickAddCategories() {
    final userConfig = config.quickAddCategories;

    if (userConfig.isNotEmpty) {
      // User has configured categories - no caching needed
      return userConfig
          .where((i) => i >= 0 && i < ExpenseCategory.values.length)
          .map((i) => ExpenseCategory.values[i])
          .take(4)
          .toList();
    }

    // Auto-learn from spending history (with caching)
    return _autoLearnCategoriesCached();
  }

  /// Auto-learn categories with caching to avoid repeated iteration.
  List<ExpenseCategory> _autoLearnCategoriesCached() {
    final now = DateTime.now();

    // Return cached result if still valid
    if (_cachedCategories != null &&
        _categoriesCacheTime != null &&
        now.difference(_categoriesCacheTime!) < _categoriesCacheDuration) {
      return _cachedCategories!;
    }

    // Compute and cache
    _cachedCategories = _autoLearnCategories();
    _categoriesCacheTime = now;
    return _cachedCategories!;
  }

  /// Invalidate category cache (call after expense add/delete).
  void invalidateCategoryCache() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
  }

  /// Analyze spending history to find top 4 most-used categories.
  List<ExpenseCategory> _autoLearnCategories() {
    if (_expenseService == null) {
      return _defaultCategories();
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Count expenses per category in last 30 days
    final categoryCounts = <ExpenseCategory, int>{};
    for (final expense in _expenseService!.getAllExpenses()) {
      if (expense.date.isAfter(thirtyDaysAgo)) {
        categoryCounts[expense.category] =
            (categoryCounts[expense.category] ?? 0) + 1;
      }
    }

    if (categoryCounts.isEmpty) {
      return _defaultCategories();
    }

    // Sort by count descending
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top 4
    final top4 = sortedCategories.take(4).map((e) => e.key).toList();

    // Pad with defaults if less than 4
    while (top4.length < 4) {
      for (final cat in _defaultCategories()) {
        if (!top4.contains(cat)) {
          top4.add(cat);
          if (top4.length >= 4) break;
        }
      }
    }

    return top4;
  }

  /// Default categories when no history exists.
  List<ExpenseCategory> _defaultCategories() {
    return [
      ExpenseCategory.food,
      ExpenseCategory.transport,
      ExpenseCategory.shopping,
      ExpenseCategory.bills,
    ];
  }

  /// Determine contextual widget message based on time/budget/upcoming.
  WidgetContext determineContext() {
    if (_expenseService == null || _budgetService == null) {
      return const WidgetContext(
        type: WidgetContextType.normal,
        statusText: 'Loading...',
        alertText: 'Tap + to add expense',
      );
    }

    final now = DateTime.now();
    final hour = now.hour;
    final dayOfMonth = now.day;
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final daysLeft = daysInMonth - dayOfMonth;

    final budget = _budgetService!.getOverallBudget(now.year, now.month);
    final summary = _expenseService!.getMonthSummary(now.year, now.month);
    final spent = summary.total;
    final pace = _expenseService!.getSpendingPace(now.year, now.month);

    // Priority order:

    // 1. Overspent warning
    if (budget != null && spent > budget.amount) {
      final overBy = spent - budget.amount;
      return WidgetContext(
        type: WidgetContextType.warning,
        statusText: 'Over budget by ${CurrencyFormatter.format(overBy)}',
        alertText: 'Tap to see details',
        alertIcon: 'warning',
      );
    }

    // 2. Month-end urgency (last 5 days)
    if (daysLeft <= 5 && daysLeft > 0 && budget != null) {
      final remaining = budget.amount - spent;
      final dailyBudget = remaining > 0 ? remaining / daysLeft : 0.0;
      return WidgetContext(
        type: WidgetContextType.urgent,
        statusText: '$daysLeft days left',
        alertText: dailyBudget > 0
            ? '${CurrencyFormatter.format(dailyBudget)}/day to stay on track'
            : 'Budget exceeded',
        alertIcon: 'calendar',
      );
    }

    // 3. Morning greeting (6am - 10am)
    if (hour >= 6 && hour < 10) {
      final yesterdaySpent = _getYesterdayTotal();
      return WidgetContext(
        type: WidgetContextType.morning,
        statusText: 'Good morning',
        alertText: yesterdaySpent > 0
            ? 'Yesterday: ${CurrencyFormatter.format(yesterdaySpent)}'
            : 'Start tracking today',
      );
    }

    // 4. Evening summary (7pm - 10pm)
    if (hour >= 19 && hour < 22) {
      final todaySpent = _getTodayTotal();
      final avgDaily = pace?.dailyAverage ?? 0;
      String alertText;
      if (todaySpent > 0 && avgDaily > 0) {
        final percentDiff =
            ((todaySpent - avgDaily) / avgDaily * 100).toInt().abs();
        if (todaySpent > avgDaily * 1.5) {
          alertText = '$percentDiff% over daily average';
        } else if (todaySpent < avgDaily * 0.5) {
          alertText = '$percentDiff% under daily average';
        } else {
          alertText = 'On track today';
        }
      } else {
        alertText = 'No expenses today';
      }
      return WidgetContext(
        type: WidgetContextType.evening,
        statusText: 'Today: ${CurrencyFormatter.format(todaySpent)}',
        alertText: alertText,
      );
    }

    // 5. Upcoming recurring expenses (next 3 days)
    if (_recurringExpenseService != null) {
      final upcomingExpenses = _recurringExpenseService!.getUpcoming(days: 3);
      if (upcomingExpenses.isNotEmpty) {
        final next = upcomingExpenses.first;
        final daysUntil = _daysUntil(next.nextDueDate);
        final daysText = daysUntil == 0
            ? 'today'
            : daysUntil == 1
                ? 'tomorrow'
                : 'in $daysUntil days';
        return WidgetContext(
          type: WidgetContextType.upcoming,
          statusText: next.title,
          alertText: '${CurrencyFormatter.format(next.amount)} $daysText',
          alertIcon: 'calendar',
        );
      }
    }

    // Note: RecurringIncomeService doesn't expose getUpcoming list yet.
    // Upcoming expenses take priority for widget alerts.

    // 6. Default: Budget status or monthly total
    if (budget != null) {
      final remaining = budget.amount - spent;
      final safeToSpend = _calculateSafeToSpend(budget.amount, spent, daysLeft);
      return WidgetContext(
        type: WidgetContextType.normal,
        statusText: '${CurrencyFormatter.format(remaining)} remaining',
        alertText: daysLeft > 0
            ? '${CurrencyFormatter.format(safeToSpend)} safe to spend'
            : 'Month ending',
      );
    }

    return WidgetContext(
      type: WidgetContextType.normal,
      statusText: '${CurrencyFormatter.format(spent)} this month',
      alertText: 'Tap + to add expense',
    );
  }

  /// Calculate safe-to-spend based on budget remaining and days left.
  double _calculateSafeToSpend(
      double budgetAmount, double spent, int daysLeft) {
    if (daysLeft <= 0) return 0;
    final remaining = budgetAmount - spent;
    if (remaining <= 0) return 0;
    return remaining / daysLeft;
  }

  /// Get yesterday's total spending.
  double _getYesterdayTotal() {
    if (_expenseService == null) return 0;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    double total = 0;
    for (final expense in _expenseService!.getAllExpenses()) {
      if (expense.date.year == yesterday.year &&
          expense.date.month == yesterday.month &&
          expense.date.day == yesterday.day) {
        total += expense.amount;
      }
    }
    return total;
  }

  /// Get today's total spending.
  double _getTodayTotal() {
    if (_expenseService == null) return 0;
    final now = DateTime.now();
    double total = 0;
    for (final expense in _expenseService!.getAllExpenses()) {
      if (expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day) {
        total += expense.amount;
      }
    }
    return total;
  }

  /// Calculate days until a date.
  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  /// Sync all widget data to SharedPreferences for native widget access.
  /// Debounced to prevent excessive writes during rapid updates.
  Future<void> syncData({bool isDarkMode = true}) async {
    // Cancel any pending sync
    _syncDebounceTimer?.cancel();

    // Debounce: wait for activity to settle before syncing
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      _performSync(isDarkMode: isDarkMode);
    });
  }

  /// Sync immediately without debouncing (use for app backgrounding).
  Future<void> syncDataImmediate({bool isDarkMode = true}) async {
    _syncDebounceTimer?.cancel();
    await _performSync(isDarkMode: isDarkMode);
  }

  /// Perform the actual sync (called after debounce).
  Future<void> _performSync({bool isDarkMode = true}) async {
    if (_expenseService == null || _budgetService == null) return;

    final now = DateTime.now();
    final budget = _budgetService!.getOverallBudget(now.year, now.month);
    final summary = _expenseService!.getMonthSummary(now.year, now.month);
    final spent = summary.total;
    final daysLeft = DateUtils.getDaysInMonth(now.year, now.month) - now.day;

    // Budget data
    await HomeWidget.saveWidgetData('budget_total', budget?.amount ?? 0.0);
    await HomeWidget.saveWidgetData('budget_spent', spent);
    await HomeWidget.saveWidgetData(
        'budget_remaining', (budget?.amount ?? 0) - spent);

    // Progress percentage
    final percentage =
        budget != null && budget.amount > 0 ? spent / budget.amount : 0.0;
    await HomeWidget.saveWidgetData('budget_percentage', percentage);
    await HomeWidget.saveWidgetData(
        'budget_percentage_text', '${(percentage * 100).toInt()}%');

    // Safe to spend
    final safeToSpend = budget != null
        ? _calculateSafeToSpend(budget.amount, spent, daysLeft)
        : 0.0;
    await HomeWidget.saveWidgetData('safe_to_spend', safeToSpend);
    await HomeWidget.saveWidgetData(
        'safe_to_spend_text', CurrencyFormatter.format(safeToSpend));

    // Days left
    await HomeWidget.saveWidgetData('days_left', daysLeft);
    await HomeWidget.saveWidgetData('days_left_text', '$daysLeft days left');

    // Status text (budget summary)
    final budgetText = budget != null
        ? '${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(budget.amount)}'
        : CurrencyFormatter.format(spent);
    await HomeWidget.saveWidgetData('budget_text', budgetText);

    // Context-aware messaging
    final context = determineContext();
    await HomeWidget.saveWidgetData('context_type', context.type.name);
    await HomeWidget.saveWidgetData('context_status', context.statusText);
    await HomeWidget.saveWidgetData('context_alert', context.alertText);
    await HomeWidget.saveWidgetData('context_icon', context.alertIcon ?? '');

    // Quick-add categories
    final categories = getQuickAddCategories();
    for (var i = 0; i < 4; i++) {
      if (i < categories.length) {
        await HomeWidget.saveWidgetData('cat_${i}_index', categories[i].index);
        await HomeWidget.saveWidgetData(
            'cat_${i}_name', _shortCategoryName(categories[i]));
        await HomeWidget.saveWidgetData(
            'cat_${i}_icon', categories[i].icon.codePoint);
      } else {
        await HomeWidget.saveWidgetData('cat_${i}_index', -1);
        await HomeWidget.saveWidgetData('cat_${i}_name', '');
        await HomeWidget.saveWidgetData('cat_${i}_icon', 0);
      }
    }

    // Theme colors
    await _syncThemeColors(isDarkMode);

    // Config flags
    await HomeWidget.saveWidgetData('show_budget', config.showBudgetProgress);
    await HomeWidget.saveWidgetData('show_alerts', config.showAlerts);

    // Last synced timestamp
    await HomeWidget.saveWidgetData('last_synced', now.millisecondsSinceEpoch);

    // Update config with sync time
    await _configBox.put('default', config.copyWith(lastSynced: now));

    // Trigger widget update
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  /// Sync theme colors to SharedPreferences.
  Future<void> _syncThemeColors(bool isDarkMode) async {
    if (isDarkMode) {
      await HomeWidget.saveWidgetData('color_background', 0xFF121212);
      await HomeWidget.saveWidgetData('color_surface', 0xFF1E1E1E);
      await HomeWidget.saveWidgetData('color_surface_highlight', 0xFF2C2C2C);
      await HomeWidget.saveWidgetData('color_accent', 0xFFA8E6CF);
      await HomeWidget.saveWidgetData('color_negative', 0xFFFF6B6B);
      await HomeWidget.saveWidgetData('color_text_primary', 0xFFFFFFFF);
      await HomeWidget.saveWidgetData('color_text_secondary', 0xB3FFFFFF);
    } else {
      await HomeWidget.saveWidgetData('color_background', 0xFFF5F5F3);
      await HomeWidget.saveWidgetData('color_surface', 0xFFFFFFFF);
      await HomeWidget.saveWidgetData('color_surface_highlight', 0xFFEBEBEA);
      await HomeWidget.saveWidgetData('color_accent', 0xFF2E9E6B);
      await HomeWidget.saveWidgetData('color_negative', 0xFFDC4444);
      await HomeWidget.saveWidgetData('color_text_primary', 0xFF1A1A1A);
      await HomeWidget.saveWidgetData('color_text_secondary', 0xB31A1A1A);
    }
    await HomeWidget.saveWidgetData('is_dark_mode', isDarkMode);
  }

  /// Get short category name for widget display.
  String _shortCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Travel';
      case ExpenseCategory.shopping:
        return 'Shop';
      case ExpenseCategory.entertainment:
        return 'Fun';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Edu';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Handle widget callback when user taps a button.
  /// Returns the category index for quick-add, or -1 for general add.
  static int? parseQuickAddCallback(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme != 'ledgerify' || uri.host != 'quick-add') return null;
    final categoryStr = uri.queryParameters['category'];
    if (categoryStr == null) return -1; // General add
    return int.tryParse(categoryStr);
  }

  /// Returns the listenable config box for reactive UI.
  Box<WidgetConfig> get configBox => _configBox;
}
