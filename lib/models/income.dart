import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'income.g.dart';

/// Enum representing the source of income.
/// Each source has a display name and icon for UI representation.
@HiveType(typeId: 9)
enum IncomeSource {
  @HiveField(0)
  salary,

  @HiveField(1)
  freelance,

  @HiveField(2)
  business,

  @HiveField(3)
  investment,

  @HiveField(4)
  gift,

  @HiveField(5)
  refund,

  @HiveField(6)
  other,
}

/// Extension to provide display names and icons for income sources.
extension IncomeSourceExtension on IncomeSource {
  String get displayName {
    switch (this) {
      case IncomeSource.salary:
        return 'Salary';
      case IncomeSource.freelance:
        return 'Freelance Income';
      case IncomeSource.business:
        return 'Business Income';
      case IncomeSource.investment:
        return 'Investment Returns';
      case IncomeSource.gift:
        return 'Gift';
      case IncomeSource.refund:
        return 'Refund';
      case IncomeSource.other:
        return 'Other';
    }
  }

  /// Returns a Material icon for the income source.
  /// Following Ledgerify Design Language - rounded, solid, minimal icons.
  IconData get icon {
    switch (this) {
      case IncomeSource.salary:
        return Icons.work_rounded;
      case IncomeSource.freelance:
        return Icons.laptop_rounded;
      case IncomeSource.business:
        return Icons.storefront_rounded;
      case IncomeSource.investment:
        return Icons.trending_up_rounded;
      case IncomeSource.gift:
        return Icons.card_giftcard_rounded;
      case IncomeSource.refund:
        return Icons.replay_rounded;
      case IncomeSource.other:
        return Icons.more_horiz_rounded;
    }
  }
}

/// Represents an allocation of income to a specific savings goal.
///
/// When income is received, users can allocate portions of it to different
/// savings goals. This class tracks both the percentage and calculated amount
/// for each allocation.
///
/// Fields:
/// - [goalId]: Reference to the Goal this allocation belongs to
/// - [percentage]: Percentage of income allocated (0-100)
/// - [amount]: Calculated amount based on percentage
@HiveType(typeId: 10)
class GoalAllocation {
  @HiveField(0)
  final String goalId;

  @HiveField(1)
  final double percentage;

  @HiveField(2)
  final double amount;

  const GoalAllocation({
    required this.goalId,
    required this.percentage,
    required this.amount,
  });

  /// Creates a copy of this allocation with optional field overrides.
  GoalAllocation copyWith({
    String? goalId,
    double? percentage,
    double? amount,
  }) {
    return GoalAllocation(
      goalId: goalId ?? this.goalId,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
    );
  }

  /// Converts the allocation to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'percentage': percentage,
      'amount': amount,
    };
  }

  /// Creates a GoalAllocation from a JSON map.
  factory GoalAllocation.fromJson(Map<String, dynamic> json) {
    return GoalAllocation(
      goalId: json['goalId'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'GoalAllocation(goalId: $goalId, percentage: $percentage%, amount: $amount)';
  }
}

/// The main Income model representing a single income entry.
///
/// Income entries track money received from various sources and can include
/// allocations to savings goals. This allows users to automatically distribute
/// portions of their income to different financial goals.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [amount]: The income amount (must be > 0)
/// - [source]: Source of the income (salary, freelance, etc.)
/// - [description]: Optional description or note
/// - [date]: When the income was received
/// - [createdAt]: When this entry was created
/// - [goalAllocations]: List of allocations to savings goals
@HiveType(typeId: 11)
class Income extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final IncomeSource source;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final List<GoalAllocation> goalAllocations;

  /// Optional reference to the recurring income template that generated this income.
  /// If set, this income was auto-generated from a RecurringIncome.
  @HiveField(7)
  final String? recurringIncomeId;

  Income({
    required this.id,
    required this.amount,
    required this.source,
    this.description,
    required this.date,
    DateTime? createdAt,
    List<GoalAllocation>? goalAllocations,
    this.recurringIncomeId,
  })  : createdAt = createdAt ?? DateTime.now(),
        goalAllocations = goalAllocations ?? [];

  /// Returns the total amount allocated to goals.
  double get totalAllocated {
    if (goalAllocations.isEmpty) return 0.0;
    return goalAllocations.fold(
        0.0, (sum, allocation) => sum + allocation.amount);
  }

  /// Returns the amount not yet allocated to any goal.
  double get unallocatedAmount {
    final unallocated = amount - totalAllocated;
    return unallocated > 0 ? unallocated : 0.0;
  }

  /// Whether this income has any goal allocations.
  bool get hasAllocations => goalAllocations.isNotEmpty;

  /// Whether this income was generated from a recurring template.
  bool get isFromRecurring => recurringIncomeId != null;

  /// Creates a copy of this income with optional field overrides.
  Income copyWith({
    String? id,
    double? amount,
    IncomeSource? source,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    List<GoalAllocation>? goalAllocations,
    String? recurringIncomeId,
    bool clearRecurringIncomeId = false,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      goalAllocations: goalAllocations ?? this.goalAllocations,
      recurringIncomeId: clearRecurringIncomeId
          ? null
          : (recurringIncomeId ?? this.recurringIncomeId),
    );
  }

  /// Converts the income to a JSON map.
  /// Useful for debugging or future export features.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'source': source.name,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'goalAllocations': goalAllocations.map((a) => a.toJson()).toList(),
      'recurringIncomeId': recurringIncomeId,
    };
  }

  /// Creates an Income from a JSON map.
  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: IncomeSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => IncomeSource.other,
      ),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      goalAllocations: (json['goalAllocations'] as List<dynamic>?)
              ?.map((e) => GoalAllocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recurringIncomeId: json['recurringIncomeId'] as String?,
    );
  }

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, source: ${source.displayName}, date: $date)';
  }
}
