import 'package:hive/hive.dart';
import 'expense.dart';

part 'budget.g.dart';

/// Budget status based on spending percentage
enum BudgetStatus { ok, warning, exceeded }

/// Represents a monthly budget for a category or overall spending
@HiveType(typeId: 5)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExpenseCategory? category; // null = overall budget

  @HiveField(2)
  final double amount; // budget limit

  @HiveField(3)
  final int year;

  @HiveField(4)
  final int month;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool warning80Sent; // true if 80% notification sent

  @HiveField(7)
  bool exceeded100Sent; // true if 100% notification sent

  Budget({
    required this.id,
    this.category,
    required this.amount,
    required this.year,
    required this.month,
    DateTime? createdAt,
    this.warning80Sent = false,
    this.exceeded100Sent = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Returns true if this is an overall budget (not category-specific)
  bool get isOverallBudget => category == null;

  /// Create a copy with optional overrides
  Budget copyWith({
    String? id,
    ExpenseCategory? category,
    double? amount,
    int? year,
    int? month,
    DateTime? createdAt,
    bool? warning80Sent,
    bool? exceeded100Sent,
    bool clearCategory = false,
  }) {
    return Budget(
      id: id ?? this.id,
      category: clearCategory ? null : (category ?? this.category),
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      warning80Sent: warning80Sent ?? this.warning80Sent,
      exceeded100Sent: exceeded100Sent ?? this.exceeded100Sent,
    );
  }

  /// Converts the budget to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category?.name,
      'amount': amount,
      'year': year,
      'month': month,
      'createdAt': createdAt.toIso8601String(),
      'warning80Sent': warning80Sent,
      'exceeded100Sent': exceeded100Sent,
    };
  }

  /// Creates a Budget from a JSON map.
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] != null
          ? ExpenseCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => ExpenseCategory.other,
            )
          : null,
      amount: (json['amount'] as num).toDouble(),
      year: json['year'] as int,
      month: json['month'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      warning80Sent: json['warning80Sent'] as bool? ?? false,
      exceeded100Sent: json['exceeded100Sent'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    final categoryStr = category?.displayName ?? 'Overall';
    return 'Budget(id: $id, category: $categoryStr, amount: $amount, $year-$month)';
  }
}

/// Represents budget progress/status
class BudgetProgress {
  final Budget budget;
  final double spent;
  final double percentage; // 0.0 to 1.0+
  final BudgetStatus status;

  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.status,
  });

  double get remaining => budget.amount - spent;
  bool get isOverBudget => spent > budget.amount;
}
