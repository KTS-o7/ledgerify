import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

/// Enum representing the source of an expense entry.
/// - manual: User entered the expense manually
/// - sms: Expense was parsed from an SMS (future feature)
/// - recurring: Expense was auto-generated from a recurring template
@HiveType(typeId: 1)
enum ExpenseSource {
  @HiveField(0)
  manual,

  @HiveField(1)
  sms,

  @HiveField(2)
  recurring,
}

/// Enum representing expense categories.
/// Kept simple for V1 - can be extended later.
@HiveType(typeId: 2)
enum ExpenseCategory {
  @HiveField(0)
  food,

  @HiveField(1)
  transport,

  @HiveField(2)
  shopping,

  @HiveField(3)
  entertainment,

  @HiveField(4)
  bills,

  @HiveField(5)
  health,

  @HiveField(6)
  education,

  @HiveField(7)
  other,
}

/// Extension to provide display names for categories.
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Returns a Material icon for the category.
  /// Following Ledgerify Design Language - rounded, solid, minimal icons.
  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}

/// The main Expense model representing a single expense entry.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [amount]: The expense amount (must be > 0)
/// - [category]: Category of the expense (built-in)
/// - [customCategoryId]: Optional custom category ID (overrides category if set)
/// - [date]: When the expense occurred
/// - [note]: Optional user note
/// - [source]: How the expense was added (manual or sms)
/// - [merchant]: Optional merchant name (useful for SMS parsing later)
/// - [tagIds]: List of tag IDs associated with this expense
@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final ExpenseCategory category;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final ExpenseSource source;

  @HiveField(6)
  final String? merchant;

  @HiveField(7)
  final DateTime createdAt;

  /// Optional custom category ID. If set, this takes precedence over [category]
  /// for display purposes, but [category] is still used for analytics grouping.
  @HiveField(8)
  final String? customCategoryId;

  /// List of tag IDs associated with this expense.
  /// Tags provide additional flexible categorization beyond the main category.
  @HiveField(9)
  final List<String> tagIds;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.source = ExpenseSource.manual,
    this.merchant,
    DateTime? createdAt,
    this.customCategoryId,
    List<String>? tagIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        tagIds = tagIds ?? [];

  /// Whether this expense uses a custom category.
  bool get hasCustomCategory => customCategoryId != null;

  /// Whether this expense has any tags.
  bool get hasTags => tagIds.isNotEmpty;

  /// Creates a copy of this expense with optional field overrides.
  Expense copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    ExpenseSource? source,
    String? merchant,
    DateTime? createdAt,
    String? customCategoryId,
    List<String>? tagIds,
    bool clearCustomCategory = false,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      source: source ?? this.source,
      merchant: merchant ?? this.merchant,
      createdAt: createdAt ?? this.createdAt,
      customCategoryId: clearCustomCategory
          ? null
          : (customCategoryId ?? this.customCategoryId),
      tagIds: tagIds ?? this.tagIds,
    );
  }

  /// Converts the expense to a JSON map.
  /// Useful for debugging or future export features.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note,
      'source': source.name,
      'merchant': merchant,
      'createdAt': createdAt.toIso8601String(),
      'customCategoryId': customCategoryId,
      'tagIds': tagIds,
    };
  }

  /// Creates an Expense from a JSON map.
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      source: ExpenseSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ExpenseSource.manual,
      ),
      merchant: json['merchant'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      customCategoryId: json['customCategoryId'] as String?,
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: ${category.displayName}, date: $date)';
  }
}
