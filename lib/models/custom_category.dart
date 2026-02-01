import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'custom_category.g.dart';

/// A user-defined custom expense category.
///
/// Allows users to create their own categories beyond the built-in ones.
/// Custom categories can have custom icons and colors.
///
/// Fields:
/// - [id]: Unique identifier (UUID)
/// - [name]: Category name (e.g., "Subscriptions", "Pets")
/// - [iconCodePoint]: Material icon codepoint (e.g., Icons.pets.codePoint)
/// - [colorHex]: Hex color string (e.g., "#9C27B0")
/// - [isActive]: Whether the category is active/visible
/// - [createdAt]: When the category was created
@HiveType(typeId: 7)
class CustomCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCodePoint;

  @HiveField(3)
  final String colorHex;

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final DateTime createdAt;

  /// Cached parsed color for performance.
  Color? _cachedColor;

  CustomCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    this.isActive = true,
    DateTime? createdAt,
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
  Color _parseColorHex() {
    String hex = colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity if not specified
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Creates a copy of this category with optional field overrides.
  CustomCategory copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? colorHex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the category to a JSON map.
  /// Useful for debugging or future export features.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a CustomCategory from a JSON map.
  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorHex: json['colorHex'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'CustomCategory(id: $id, name: $name, isActive: $isActive)';
  }
}
