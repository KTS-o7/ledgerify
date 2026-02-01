import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'goal.g.dart';

/// A savings goal model for tracking financial targets.
///
/// Goals allow users to set and track savings targets like "Vacation Fund",
/// "Emergency Fund", or "New Phone". Each goal has a target amount, current
/// progress, optional deadline, and visual customization.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [name]: Goal name (e.g., "Vacation Fund", "Emergency Fund")
/// - [targetAmount]: Target amount to save
/// - [currentAmount]: Amount saved so far
/// - [iconCodePoint]: Material icon codepoint for visual representation
/// - [colorHex]: Hex color string (e.g., "#4CAF50")
/// - [deadline]: Optional target date to achieve the goal
/// - [isCompleted]: Whether the goal has been achieved
/// - [createdAt]: When the goal was created
/// - [completedAt]: When the goal was completed (if applicable)
@HiveType(typeId: 8)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final double currentAmount;

  @HiveField(4)
  final int iconCodePoint;

  @HiveField(5)
  final String colorHex;

  @HiveField(6)
  final DateTime? deadline;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? completedAt;

  /// Cached parsed color for performance.
  Color? _cachedColor;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.iconCodePoint,
    required this.colorHex,
    this.deadline,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Returns the IconData from the stored codepoint.
  /// Uses Material Icons with rounded style for consistency with Ledgerify design.
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// Returns the color as a Flutter Color object.
  /// Caches the parsed result for performance.
  Color get color {
    if (_cachedColor != null) return _cachedColor!;
    _cachedColor = _parseColorHex();
    return _cachedColor!;
  }

  /// Parses the colorHex string to a Flutter Color.
  /// Supports formats: "#RRGGBB" or "#AARRGGBB"
  /// Falls back to accent color if parsing fails.
  Color _parseColorHex() {
    try {
      final hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      // Fall through to default
    }
    // Default to accent color if parsing fails
    return const Color(0xFFA8E6CF);
  }

  /// Returns the progress as a ratio of currentAmount to targetAmount.
  /// Returns 0.0 if targetAmount is 0 to avoid division by zero.
  /// Can return values greater than 1.0 if currentAmount exceeds targetAmount.
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return currentAmount / targetAmount;
  }

  /// Returns the remaining amount needed to reach the target.
  /// Returns 0.0 if the goal is already met or exceeded.
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Returns true if the deadline has passed and the goal is not completed.
  bool get isOverdue {
    if (isCompleted || deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Creates a copy of this goal with optional field overrides.
  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? iconCodePoint,
    String? colorHex,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Converts the goal to a JSON map.
  /// Useful for debugging or future export features.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Creates a Goal from a JSON map.
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      iconCodePoint: json['iconCodePoint'] as int,
      colorHex: json['colorHex'] as String,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, progress: ${(progress * 100).toStringAsFixed(1)}%, isCompleted: $isCompleted)';
  }
}
