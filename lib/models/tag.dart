import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tag.g.dart';

/// A Tag model for categorizing and labeling expenses.
///
/// Tags provide flexible labeling beyond categories, allowing users
/// to mark expenses as "vacation", "reimbursable", "tax-deductible", etc.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [name]: Tag name (e.g., "vacation", "reimbursable")
/// - [colorHex]: Hex color string for visual distinction (e.g., "#FF5722")
/// - [createdAt]: When the tag was created
@HiveType(typeId: 6)
class Tag extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String colorHex;

  @HiveField(3)
  final DateTime createdAt;

  /// Cached parsed color for performance.
  Color? _cachedColor;

  Tag({
    required this.id,
    required this.name,
    required this.colorHex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Returns the color as a Flutter Color object.
  /// Caches the parsed result for performance.
  Color get color {
    if (_cachedColor != null) return _cachedColor!;
    _cachedColor = _parseColorHex();
    return _cachedColor!;
  }

  /// Parses the colorHex string to a Flutter Color.
  /// Falls back to a default accent color if parsing fails.
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

  /// Creates a copy of this tag with optional field overrides.
  Tag copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the tag to a JSON map.
  /// Useful for debugging or future export features.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a Tag from a JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, colorHex: $colorHex)';
  }
}
