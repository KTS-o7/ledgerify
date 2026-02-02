import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/smart_insight.dart';
import '../utils/currency_formatter.dart';
import 'budget_service.dart';
import 'expense_service.dart';
import 'income_service.dart';

/// Service class for generating smart insights from expense data.
///
/// Analyzes spending patterns and generates actionable insights following
/// Quiet Finance principles:
/// - Factual, not emotional (no "Great job!" or "Uh oh!")
/// - Professional tone
/// - Format: "Category up/down X% — reason"
///
/// Insight types:
/// - Category comparisons vs last month (>25% change)
/// - Budget warnings (on pace to exceed)
/// - Anomaly detection (>2x average)
/// - Achievement insights (lowest in 3+ months)
class InsightService {
  static const Uuid _uuid = Uuid();

  final ExpenseService expenseService;
  final IncomeService incomeService;
  final BudgetService budgetService;

  /// Threshold for category comparison insights (25% change).
  static const double _comparisonThreshold = 0.25;

  /// Threshold for anomaly detection (2x average).
  static const double _anomalyMultiplier = 2.0;

  /// Number of months to look back for achievement detection.
  static const int _achievementLookbackMonths = 3;

  /// Maximum number of insights to return.
  static const int _maxInsights = 3;

  /// Month names for display.
  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  InsightService({
    required this.expenseService,
    required this.incomeService,
    required this.budgetService,
  });

  /// Generates a unique ID for an insight.
  String _generateId() => _uuid.v4();

  /// Generate insights for a given month.
  ///
  /// Analyzes expense data and returns up to 3 prioritized insights.
  /// Insights are sorted by priority (high first).
  ///
  /// Performance: All data is fetched ONCE at the beginning and passed
  /// to child methods to avoid redundant O(n) iterations.
  List<SmartInsight> generateInsights(int year, int month) {
    final insights = <SmartInsight>[];

    // Fetch all data ONCE at the beginning
    final currentSummary = expenseService.getMonthSummary(year, month);

    // Get previous month
    final prevYear = month == 1 ? year - 1 : year;
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevSummary = expenseService.getMonthSummary(prevYear, prevMonth);

    // Get budgets
    final budgets = budgetService.getAllBudgetsForMonth(year, month);

    // Pre-calculate historical data for both anomalies and achievements (3 months)
    final historicalSummaries = <MonthSummary>[];
    var histYear = year;
    var histMonth = month;
    for (int i = 0; i < _achievementLookbackMonths; i++) {
      histMonth--;
      if (histMonth <= 0) {
        histMonth = 12;
        histYear--;
      }
      historicalSummaries
          .add(expenseService.getMonthSummary(histYear, histMonth));
    }

    // 1. Category comparison insights (vs last month)
    insights.addAll(
        _generateCategoryComparisons(year, month, currentSummary, prevSummary));

    // 2. Budget warning insights
    insights
        .addAll(_generateBudgetWarnings(year, month, currentSummary, budgets));

    // 3. Anomaly detection (unusual transactions)
    insights.addAll(
        _generateAnomalies(year, month, currentSummary, historicalSummaries));

    // 4. Achievement insights (positive milestones)
    insights.addAll(_generateAchievements(
        year, month, currentSummary, historicalSummaries));

    // Sort by priority (high = 0, medium = 1, low = 2)
    insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    // Return top N insights
    return insights.take(_maxInsights).toList();
  }

  // ============================================================================
  // Category Comparisons
  // ============================================================================

  /// Generate insights for categories with significant change vs last month.
  ///
  /// Triggers when category spending changed >25%.
  /// Format: "Food up 34%" or "Transport down 45%"
  List<SmartInsight> _generateCategoryComparisons(
    int year,
    int month,
    MonthSummary currentSummary,
    MonthSummary prevSummary,
  ) {
    final insights = <SmartInsight>[];

    // Skip if no previous month data
    if (prevSummary.total == 0) return insights;

    // Analyze each category
    for (final category in ExpenseCategory.values) {
      final current = currentSummary.breakdown[category] ?? 0;
      final previous = prevSummary.breakdown[category] ?? 0;

      // Skip if no spending in either month
      if (current == 0 && previous == 0) continue;

      // Calculate percentage change
      double percentChange;
      if (previous == 0) {
        // New spending in this category
        if (current > 0) {
          percentChange = 1.0; // 100% increase (new category)
        } else {
          continue;
        }
      } else {
        percentChange = (current - previous) / previous;
      }

      // Only generate insight if change exceeds threshold
      if (percentChange.abs() < _comparisonThreshold) continue;

      final isIncrease = percentChange > 0;
      final percentDisplay = (percentChange.abs() * 100).toStringAsFixed(0);
      final direction = isIncrease ? 'up' : 'down';

      // Get transaction IDs for drill-down
      final relatedExpenses = currentSummary.expenses
          .where((e) => e.category == category)
          .map((e) => e.id)
          .toList();

      // Build description with context
      final description = _buildComparisonDescription(
        category,
        current,
        previous,
        currentSummary.expenses.where((e) => e.category == category).toList(),
      );

      insights.add(SmartInsight(
        id: _generateId(),
        type: InsightType.comparison,
        priority: isIncrease ? InsightPriority.medium : InsightPriority.low,
        title: '${category.displayName} $direction $percentDisplay%',
        description: description,
        amount: current,
        categoryName: category.displayName,
        category: category,
        relatedTransactionIds: relatedExpenses,
      ));
    }

    return insights;
  }

  /// Build a contextual description for category comparison.
  String _buildComparisonDescription(
    ExpenseCategory category,
    double current,
    double previous,
    List<Expense> expenses,
  ) {
    final currentFormatted = CurrencyFormatter.format(current);
    final previousFormatted = CurrencyFormatter.format(previous);

    // Count transactions
    final txCount = expenses.length;

    // Find top merchant if available
    final merchantCounts = <String, int>{};
    for (final expense in expenses) {
      if (expense.merchant != null && expense.merchant!.isNotEmpty) {
        merchantCounts[expense.merchant!] =
            (merchantCounts[expense.merchant!] ?? 0) + 1;
      }
    }

    String detail = '$currentFormatted vs $previousFormatted last month';

    if (merchantCounts.isNotEmpty) {
      // Find most frequent merchant
      final topMerchant = merchantCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final merchantCount = merchantCounts[topMerchant]!;

      if (merchantCount > 1) {
        detail = '$merchantCount $topMerchant orders ($currentFormatted)';
      } else {
        detail = '$txCount transactions ($currentFormatted)';
      }
    } else if (txCount > 0) {
      detail = '$txCount transactions ($currentFormatted)';
    }

    return detail;
  }

  // ============================================================================
  // Budget Warnings
  // ============================================================================

  /// Generate warnings for budgets on pace to be exceeded.
  ///
  /// Calculates daily spending rate and projects end-of-month total.
  /// Format: "At current pace, you'll exceed food budget by ₹3,200"
  List<SmartInsight> _generateBudgetWarnings(
    int year,
    int month,
    MonthSummary currentSummary,
    List<Budget> budgets,
  ) {
    final insights = <SmartInsight>[];

    if (budgets.isEmpty) return insights;

    // Calculate days elapsed and remaining
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;

    // If not current month, skip pace-based warnings
    if (!isCurrentMonth) return insights;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysElapsed = now.day;
    final daysRemaining = daysInMonth - daysElapsed;

    // Need at least a few days of data for meaningful projection
    if (daysElapsed < 3) return insights;

    for (final budget in budgets) {
      final spent = budget.isOverallBudget
          ? currentSummary.total
          : currentSummary.breakdown[budget.category] ?? 0;

      // Skip if no spending yet
      if (spent == 0) continue;

      // Calculate daily rate and projected total
      final dailyRate = spent / daysElapsed;
      final projectedTotal = spent + (dailyRate * daysRemaining);

      // Check if projected to exceed budget
      if (projectedTotal <= budget.amount) continue;

      // Already exceeded - different message
      if (spent >= budget.amount) continue;

      final exceededBy = projectedTotal - budget.amount;
      final label =
          budget.isOverallBudget ? 'monthly' : budget.category!.displayName;
      final exceededFormatted = CurrencyFormatter.format(exceededBy);

      // Get related transaction IDs
      List<String>? relatedIds;
      if (!budget.isOverallBudget) {
        relatedIds = currentSummary.expenses
            .where((e) => e.category == budget.category)
            .map((e) => e.id)
            .toList();
      }

      insights.add(SmartInsight(
        id: _generateId(),
        type: InsightType.warning,
        priority: InsightPriority.high,
        title:
            '${label.substring(0, 1).toUpperCase()}${label.substring(1)} budget at risk',
        description: 'At current pace, you\'ll exceed by $exceededFormatted',
        amount: projectedTotal,
        categoryName:
            budget.isOverallBudget ? 'Overall' : budget.category!.displayName,
        category: budget.category,
        relatedTransactionIds: relatedIds,
      ));
    }

    return insights;
  }

  // ============================================================================
  // Anomaly Detection
  // ============================================================================

  /// Detect unusual transactions (>2x the average for category).
  ///
  /// Looks at individual transactions and compares to historical average.
  /// Format: "Unusual: ₹12,000 at Amazon (typically ₹3,000)"
  List<SmartInsight> _generateAnomalies(
    int year,
    int month,
    MonthSummary currentSummary,
    List<MonthSummary> historicalSummaries,
  ) {
    final insights = <SmartInsight>[];

    // Get current month expenses from pre-fetched summary
    final expenses = currentSummary.expenses;
    if (expenses.isEmpty) return insights;

    // Calculate category averages from historical summaries
    final categoryAverages =
        _calculateCategoryAveragesFromSummaries(historicalSummaries);

    for (final expense in expenses) {
      final average = categoryAverages[expense.category];
      if (average == null || average == 0) continue;

      // Check if this transaction is anomalous (>2x average)
      if (expense.amount < average * _anomalyMultiplier) continue;

      final amountFormatted = CurrencyFormatter.format(expense.amount);
      final averageFormatted = CurrencyFormatter.format(average);

      String title;
      String description;

      if (expense.merchant != null && expense.merchant!.isNotEmpty) {
        title = 'Unusual: $amountFormatted at ${expense.merchant}';
        description =
            'Typically ${expense.category.displayName} transactions average $averageFormatted';
      } else {
        title = 'Unusual ${expense.category.displayName}: $amountFormatted';
        description =
            'Category transactions typically average $averageFormatted';
      }

      insights.add(SmartInsight(
        id: _generateId(),
        type: InsightType.anomaly,
        priority: InsightPriority.high,
        title: title,
        description: description,
        amount: expense.amount,
        categoryName: expense.category.displayName,
        category: expense.category,
        relatedTransactionIds: [expense.id],
      ));
    }

    return insights;
  }

  /// Calculate average transaction amount per category from pre-fetched summaries.
  Map<ExpenseCategory, double> _calculateCategoryAveragesFromSummaries(
    List<MonthSummary> historicalSummaries,
  ) {
    final categoryTotals = <ExpenseCategory, double>{};
    final categoryCounts = <ExpenseCategory, int>{};

    // Process each pre-fetched summary
    for (final summary in historicalSummaries) {
      for (final expense in summary.expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
        categoryCounts[expense.category] =
            (categoryCounts[expense.category] ?? 0) + 1;
      }
    }

    // Calculate averages
    final averages = <ExpenseCategory, double>{};
    for (final category in categoryTotals.keys) {
      final total = categoryTotals[category]!;
      final count = categoryCounts[category]!;
      averages[category] = total / count;
    }

    return averages;
  }

  // ============================================================================
  // Achievement Insights
  // ============================================================================

  /// Generate achievements for lowest category spending in 3+ months.
  ///
  /// Compares current month to historical lows.
  /// Format: "Transport: lowest since March"
  List<SmartInsight> _generateAchievements(
    int year,
    int month,
    MonthSummary currentSummary,
    List<MonthSummary> historicalSummaries,
  ) {
    final insights = <SmartInsight>[];

    // Need spending data to compare
    if (currentSummary.total == 0) return insights;

    // Build historical data from pre-fetched summaries
    // We need to track year/month for each summary to display "lowest since X"
    final historicalData = _getHistoricalCategoryTotalsFromSummaries(
      year,
      month,
      historicalSummaries,
    );

    for (final category in ExpenseCategory.values) {
      final current = currentSummary.breakdown[category] ?? 0;

      // Skip if no spending this month
      if (current == 0) continue;

      final history = historicalData[category];
      if (history == null || history.isEmpty) continue;

      // Check if current is lowest
      final allLower = history.every((h) => current < h.total);
      if (!allLower) continue;

      // Get the oldest month we compared against
      final oldestMonth = history.last;
      final monthName = _monthNames[oldestMonth.month];

      final amountFormatted = CurrencyFormatter.format(current);

      insights.add(SmartInsight(
        id: _generateId(),
        type: InsightType.achievement,
        priority: InsightPriority.low,
        title: '${category.displayName}: lowest since $monthName',
        description: '$amountFormatted this month',
        amount: current,
        categoryName: category.displayName,
        category: category,
        relatedTransactionIds: currentSummary.expenses
            .where((e) => e.category == category)
            .map((e) => e.id)
            .toList(),
      ));
    }

    return insights;
  }

  /// Get historical category totals from pre-fetched summaries.
  ///
  /// Takes starting year/month to calculate the actual dates for each summary.
  Map<ExpenseCategory, List<({int year, int month, double total})>>
      _getHistoricalCategoryTotalsFromSummaries(
    int year,
    int month,
    List<MonthSummary> historicalSummaries,
  ) {
    final result =
        <ExpenseCategory, List<({int year, int month, double total})>>{};

    var currentYear = year;
    var currentMonth = month;

    for (final summary in historicalSummaries) {
      // Calculate the year/month for this summary
      currentMonth--;
      if (currentMonth <= 0) {
        currentMonth = 12;
        currentYear--;
      }

      for (final category in ExpenseCategory.values) {
        final total = summary.breakdown[category] ?? 0;
        if (total > 0) {
          result.putIfAbsent(category, () => []);
          result[category]!.add((
            year: currentYear,
            month: currentMonth,
            total: total,
          ));
        }
      }
    }

    return result;
  }
}
