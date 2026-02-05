import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../theme/ledgerify_theme.dart';

/// Tag Management Screen - Ledgerify Design Language
///
/// Allows users to create, edit, and delete expense tags.
/// Accessible from Settings screen.
class TagManagementScreen extends StatelessWidget {
  final TagService tagService;

  const TagManagementScreen({
    super.key,
    required this.tagService,
  });

  /// Preset color options for tags (hex strings for storage)
  /// Colors chosen for visibility on both dark and light backgrounds
  static const List<String> _colorOptionsHex = [
    '#66BB6A', // Green
    '#EF5350', // Red
    '#42A5F5', // Blue
    '#AB47BC', // Purple
    '#FFA726', // Orange
    '#26A69A', // Teal
    '#EC407A', // Pink
    '#7E57C2', // Deep Purple
  ];

  /// Pre-computed Color objects to avoid parsing on every build
  static final List<Color> _colorOptions = _colorOptionsHex.map((hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }).toList();

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tags',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tags',
        onPressed: () => _showAddEditBottomSheet(context, null),
        backgroundColor: colors.accent,
        foregroundColor: colors.background,
        child: const Icon(Icons.add_rounded),
      ),
      body: ValueListenableBuilder<Box<Tag>>(
        valueListenable: tagService.box.listenable(),
        builder: (context, box, _) {
          final tags = tagService.getAllTags();

          if (tags.isEmpty) {
            return _EmptyState(colors: colors);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return _TagListItem(
                tag: tag,
                colors: colors,
                onTap: () => _showAddEditBottomSheet(context, tag),
                onDelete: () => _deleteTag(context, tag),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditBottomSheet(BuildContext context, Tag? tag) {
    final colors = LedgerifyColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => _AddEditTagBottomSheet(
        tagService: tagService,
        existingTag: tag,
        colors: colors,
        colorOptionsHex: _colorOptionsHex,
        colorOptions: _colorOptions,
      ),
    );
  }

  Future<void> _deleteTag(BuildContext context, Tag tag) async {
    await tagService.deleteTag(tag.id);
  }
}

/// Empty state when no tags exist
class _EmptyState extends StatelessWidget {
  final LedgerifyColorScheme colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline_rounded,
              size: 64,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No tags yet',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Tap + to create your first tag',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single tag list item with swipe to delete
class _TagListItem extends StatelessWidget {
  final Tag tag;
  final LedgerifyColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TagListItem({
    required this.tag,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LedgerifySpacing.sm),
      child: Dismissible(
        key: Key(tag.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.negative,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Icon(
            Icons.delete_rounded,
            color: colors.background,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.xs,
            ),
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              tag.name,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: colors.textTertiary,
                size: 20,
              ),
              onPressed: onTap,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for adding or editing a tag
class _AddEditTagBottomSheet extends StatefulWidget {
  final TagService tagService;
  final Tag? existingTag;
  final LedgerifyColorScheme colors;
  final List<String> colorOptionsHex;
  final List<Color> colorOptions;

  const _AddEditTagBottomSheet({
    required this.tagService,
    required this.existingTag,
    required this.colors,
    required this.colorOptionsHex,
    required this.colorOptions,
  });

  @override
  State<_AddEditTagBottomSheet> createState() => _AddEditTagBottomSheetState();
}

class _AddEditTagBottomSheetState extends State<_AddEditTagBottomSheet> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingTag != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingTag?.name ?? '',
    );
    _selectedColor =
        widget.existingTag?.colorHex ?? widget.colorOptionsHex.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        top: LedgerifySpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + LedgerifySpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            LedgerifySpacing.verticalLg,

            // Title
            Text(
              _isEditing ? 'Edit Tag' : 'New Tag',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalXl,

            // Name field
            Text(
              'Name',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            TextFormField(
              controller: _nameController,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., vacation, reimbursable, work',
                hintStyle: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textTertiary,
                ),
                filled: true,
                fillColor: colors.surfaceHighlight,
                border: const OutlineInputBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  borderSide: BorderSide(color: colors.accent, width: 1),
                ),
              ),
              validator: (value) {
                final trimmedName = value?.trim() ?? '';
                if (trimmedName.isEmpty) {
                  return 'Please enter a tag name';
                }
                // Check for duplicates using the efficient method
                if (widget.tagService.tagExists(trimmedName)) {
                  // If editing, allow the same name for the current tag
                  if (widget.existingTag != null &&
                      widget.existingTag!.name.toLowerCase() ==
                          trimmedName.toLowerCase()) {
                    return null;
                  }
                  return 'A tag with this name already exists';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            LedgerifySpacing.verticalXl,

            // Color picker
            Text(
              'Color',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            _ColorPicker(
              colors: colors,
              colorOptionsHex: widget.colorOptionsHex,
              colorOptions: widget.colorOptions,
              selectedColor: _selectedColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            LedgerifySpacing.verticalXl,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.textTertiary),
                      shape: LedgerifyRadius.shapeMd,
                      padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                LedgerifySpacing.horizontalMd,
                Expanded(
                  child: FilledButton(
                    onPressed: _saveTag,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.background,
                      shape: LedgerifyRadius.shapeMd,
                      padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            LedgerifySpacing.verticalSm,
          ],
        ),
      ),
    );
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    if (_isEditing) {
      final updatedTag = widget.existingTag!.copyWith(
        name: name,
        colorHex: _selectedColor,
      );
      await widget.tagService.updateTag(updatedTag);
    } else {
      await widget.tagService.createTag(
        name: name,
        colorHex: _selectedColor,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

/// Color picker grid with 8 preset colors
class _ColorPicker extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final List<String> colorOptionsHex;
  final List<Color> colorOptions;
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const _ColorPicker({
    required this.colors,
    required this.colorOptionsHex,
    required this.colorOptions,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LedgerifySpacing.md,
      runSpacing: LedgerifySpacing.md,
      children: List.generate(colorOptions.length, (index) {
        final colorHex = colorOptionsHex[index];
        final color = colorOptions[index];
        final isSelected = colorHex == selectedColor;

        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: colors.textPrimary, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 20,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
