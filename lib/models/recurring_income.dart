import 'package:hive/hive.dart';
import 'income.dart';
import 'recurring_expense.dart';

part 'recurring_income.g.dart';

/// Model representing a recurring income template.
///
/// This defines a pattern for income that repeats on a schedule (e.g., monthly salary).
/// The system generates actual [Income] entries based on this template.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [amount]: The income amount
/// - [source]: Source of the income (from IncomeSource enum)
/// - [description]: Optional description
/// - [frequency]: How often the income repeats (weekly, monthly, yearly)
/// - [nextDate]: The next expected income date
/// - [isActive]: Whether the recurring income is active (can be paused)
/// - [goalAllocations]: Auto-allocations to savings goals
/// - [createdAt]: When this recurring income was created
/// - [lastGeneratedDate]: The last time an income entry was auto-generated
@HiveType(typeId: 12)
class RecurringIncome extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final IncomeSource source;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final RecurrenceFrequency frequency;

  @HiveField(5)
  final DateTime nextDate;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final List<GoalAllocation> goalAllocations;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? lastGeneratedDate;

  RecurringIncome({
    required this.id,
    required this.amount,
    required this.source,
    this.description,
    required this.frequency,
    required this.nextDate,
    this.isActive = true,
    List<GoalAllocation>? goalAllocations,
    DateTime? createdAt,
    this.lastGeneratedDate,
  })  : goalAllocations = goalAllocations ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Returns true if nextDate is today or in the past.
  bool get isDue {
    if (!isActive) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return !dueDate.isAfter(today);
  }

  /// Returns the number of days until nextDate.
  /// Negative values indicate overdue days.
  int get daysUntilNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return dueDate.difference(today).inDays;
  }

  /// Returns the sum of all goal allocation percentages.
  double get totalAllocatedPercentage {
    if (goalAllocations.isEmpty) return 0.0;
    return goalAllocations.fold(
      0.0,
      (sum, allocation) => sum + allocation.percentage,
    );
  }

  /// Creates a copy of this recurring income with optional field overrides.
  RecurringIncome copyWith({
    String? id,
    double? amount,
    IncomeSource? source,
    String? description,
    RecurrenceFrequency? frequency,
    DateTime? nextDate,
    bool? isActive,
    List<GoalAllocation>? goalAllocations,
    DateTime? createdAt,
    DateTime? lastGeneratedDate,
    bool clearDescription = false,
    bool clearLastGeneratedDate = false,
  }) {
    return RecurringIncome(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      description: clearDescription ? null : (description ?? this.description),
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
      goalAllocations: goalAllocations ?? this.goalAllocations,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedDate: clearLastGeneratedDate
          ? null
          : (lastGeneratedDate ?? this.lastGeneratedDate),
    );
  }

  /// Converts the recurring income to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'source': source.name,
      'description': description,
      'frequency': frequency.name,
      'nextDate': nextDate.toIso8601String(),
      'isActive': isActive,
      'goalAllocations': goalAllocations.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
    };
  }

  /// Creates a RecurringIncome from a JSON map.
  factory RecurringIncome.fromJson(Map<String, dynamic> json) {
    return RecurringIncome(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: IncomeSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => IncomeSource.other,
      ),
      description: json['description'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      nextDate: DateTime.parse(json['nextDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      goalAllocations: (json['goalAllocations'] as List<dynamic>?)
              ?.map((e) => GoalAllocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastGeneratedDate: json['lastGeneratedDate'] != null
          ? DateTime.parse(json['lastGeneratedDate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'RecurringIncome(id: $id, amount: $amount, source: ${source.displayName}, '
        'frequency: ${frequency.displayName}, isActive: $isActive)';
  }
}
