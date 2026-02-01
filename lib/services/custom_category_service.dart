import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_category.dart';

/// Service class for managing custom expense categories with Hive local storage.
///
/// This service provides CRUD operations for user-defined categories
/// and utility methods for filtering and validation.
class CustomCategoryService {
  static const Uuid _uuid = Uuid();

  final Box<CustomCategory> _categoryBox;

  /// Creates a CustomCategoryService with the provided Hive box.
  CustomCategoryService(this._categoryBox);

  /// Returns the listenable box for reactive UI updates.
  /// Use this with ValueListenableBuilder to rebuild UI on data changes.
  Box<CustomCategory> get box => _categoryBox;

  /// Generates a new unique ID for a category.
  String generateId() => _uuid.v4();

  /// Retrieves all categories, sorted by name (case-insensitive).
  List<CustomCategory> getAllCategories() {
    final categories = _categoryBox.values.toList();
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return categories;
  }

  /// Retrieves only active categories, sorted by name (case-insensitive).
  List<CustomCategory> getActiveCategories() {
    final categories =
        _categoryBox.values.where((category) => category.isActive).toList();
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return categories;
  }

  /// Retrieves a single category by ID.
  /// Returns null if not found.
  CustomCategory? getCategory(String id) {
    return _categoryBox.get(id);
  }

  /// Creates a new custom category.
  /// Returns the created category.
  Future<CustomCategory> createCategory({
    required String name,
    required int iconCodePoint,
    required String colorHex,
  }) async {
    final category = CustomCategory(
      id: generateId(),
      name: name,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      isActive: true,
    );

    await _categoryBox.put(category.id, category);
    return category;
  }

  /// Updates an existing category.
  Future<void> updateCategory(CustomCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  /// Toggles the isActive status of a category.
  Future<void> toggleActive(String id) async {
    final category = _categoryBox.get(id);
    if (category == null) return;

    final updated = category.copyWith(isActive: !category.isActive);
    await _categoryBox.put(id, updated);
  }

  /// Deletes a category by ID.
  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  /// Checks if a category with the given name already exists (case-insensitive).
  bool categoryExists(String name) {
    final lowerName = name.toLowerCase();
    return _categoryBox.values.any(
      (category) => category.name.toLowerCase() == lowerName,
    );
  }
}
