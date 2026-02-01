import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';

/// Service class for managing expense tags with Hive local storage.
///
/// This service provides CRUD operations for tags that can be used
/// to label and categorize expenses beyond the standard categories.
class TagService {
  static const Uuid _uuid = Uuid();

  final Box<Tag> _tagBox;

  /// Creates a TagService with the given Hive box.
  TagService(this._tagBox);

  /// Returns the listenable box for reactive UI updates.
  /// Use this with ValueListenableBuilder to rebuild UI on data changes.
  Box<Tag> get box => _tagBox;

  /// Generates a new unique ID for a tag.
  String generateId() => _uuid.v4();

  /// Retrieves all tags, sorted by name (case-insensitive).
  List<Tag> getAllTags() {
    final tags = _tagBox.values.toList();
    tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return tags;
  }

  /// Retrieves a single tag by ID.
  /// Returns null if not found.
  Tag? getTag(String id) {
    return _tagBox.get(id);
  }

  /// Retrieves multiple tags by their IDs.
  /// Returns only tags that exist (non-existent IDs are ignored).
  List<Tag> getTagsByIds(List<String> ids) {
    final tags = <Tag>[];
    for (final id in ids) {
      final tag = _tagBox.get(id);
      if (tag != null) {
        tags.add(tag);
      }
    }
    return tags;
  }

  /// Creates a new tag with the given name and color.
  /// Returns the created tag.
  Future<Tag> createTag({
    required String name,
    required String colorHex,
  }) async {
    final tag = Tag(
      id: generateId(),
      name: name,
      colorHex: colorHex,
    );

    await _tagBox.put(tag.id, tag);
    return tag;
  }

  /// Updates an existing tag.
  Future<void> updateTag(Tag tag) async {
    await _tagBox.put(tag.id, tag);
  }

  /// Deletes a tag by ID.
  Future<void> deleteTag(String id) async {
    await _tagBox.delete(id);
  }

  /// Checks if a tag with the given name already exists (case-insensitive).
  bool tagExists(String name) {
    final lowerName = name.toLowerCase();
    return _tagBox.values.any((tag) => tag.name.toLowerCase() == lowerName);
  }
}
