import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../theme/ledgerify_theme.dart';

/// Tag Chip Input Widget - Ledgerify Design Language
///
/// A widget for selecting and displaying tags on an expense form.
/// Follows Quiet Finance design principles: calm, focused, minimal.
///
/// Features:
/// - Horizontal scrollable row of tag chips
/// - Selected tags shown as filled chips with tag color
/// - Unselected tags shown as outlined chips
/// - "+" button to add new tags via bottom sheet
class TagChipInput extends StatefulWidget {
  /// Service for fetching and creating tags
  final TagService tagService;

  /// Currently selected tag IDs
  final List<String> selectedTagIds;

  /// Callback when tag selection changes
  final ValueChanged<List<String>> onTagsChanged;

  const TagChipInput({
    super.key,
    required this.tagService,
    required this.selectedTagIds,
    required this.onTagsChanged,
  });

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  void _toggleTag(String tagId) {
    final newSelection = List<String>.from(widget.selectedTagIds);
    if (newSelection.contains(tagId)) {
      newSelection.remove(tagId);
    } else {
      newSelection.add(tagId);
    }
    widget.onTagsChanged(newSelection);
  }

  void _showAddTagSheet(BuildContext context) {
    showModalBottomSheet<Tag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTagSheet(tagService: widget.tagService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return ValueListenableBuilder(
      valueListenable: widget.tagService.box.listenable(),
      builder: (context, _, __) {
        final tags = widget.tagService.getAllTags();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              'Tags',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            // Horizontal scrollable row of chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length + 1, // +1 for add button
                separatorBuilder: (_, __) => LedgerifySpacing.horizontalSm,
                itemBuilder: (context, index) {
                  // Add button at the end
                  if (index == tags.length) {
                    return _buildAddButton(colors, context);
                  }
                  // Tag chip
                  final tag = tags[index];
                  final isSelected = widget.selectedTagIds.contains(tag.id);
                  return _buildTagChip(tag, isSelected, colors);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTagChip(Tag tag, bool isSelected, LedgerifyColorScheme colors) {
    return GestureDetector(
      onTap: () => _toggleTag(tag.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 32,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? tag.color : Colors.transparent,
          borderRadius: LedgerifyRadius.borderRadiusSm,
          border: isSelected
              ? null
              : Border.all(
                  color: tag.color.withValues(alpha: 0.5),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.name,
              style: LedgerifyTypography.labelMedium.copyWith(
                color:
                    isSelected ? _getContrastTextColor(tag.color) : tag.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              LedgerifySpacing.horizontalXs,
              Icon(
                Icons.check_rounded,
                size: 14,
                color: _getContrastTextColor(tag.color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(LedgerifyColorScheme colors, BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddTagSheet(context),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
            LedgerifySpacing.horizontalXs,
            Text(
              'Add',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns appropriate text color for contrast against a background color
  Color _getContrastTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be dark or light
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }
}

/// Bottom sheet for adding a new tag
class _AddTagSheet extends StatefulWidget {
  final TagService tagService;

  const _AddTagSheet({required this.tagService});

  @override
  State<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<_AddTagSheet> {
  final _nameController = TextEditingController();
  String _selectedColorHex = '#66BB6A'; // Default to green

  // 6 preset colors for tag selection (hex strings for storage)
  // Colors chosen for visibility on both dark and light backgrounds
  static const List<String> _presetColorHex = [
    '#66BB6A', // Green (darker than accent for visibility)
    '#EF5350', // Red
    '#42A5F5', // Blue
    '#AB47BC', // Purple
    '#FFA726', // Orange
    '#26A69A', // Teal
  ];

  // Pre-computed Color objects to avoid parsing on every build
  static final List<Color> _presetColors = _presetColorHex.map((hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }).toList();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    return name.isNotEmpty && !widget.tagService.tagExists(name);
  }

  Future<void> _saveTag() async {
    if (!_canSave) return;

    final tag = await widget.tagService.createTag(
      name: _nameController.text.trim(),
      colorHex: _selectedColorHex,
    );

    if (mounted) {
      Navigator.pop(context, tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(colors),
              LedgerifySpacing.verticalXl,
              // Name field
              _buildNameField(colors),
              LedgerifySpacing.verticalXl,
              // Color picker
              _buildColorPicker(colors),
              LedgerifySpacing.verticalXl,
              // Action buttons
              _buildActionButtons(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'New Tag',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(LedgerifySpacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Vacation, Reimbursable',
            hintStyle: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.surfaceHighlight,
            border: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: colors.accent,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.md,
              vertical: LedgerifySpacing.md,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildColorPicker(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(_presetColors.length, (index) {
            final colorHex = _presetColorHex[index];
            final color = _presetColors[index];
            final isSelected = _selectedColorHex == colorHex;
            return Padding(
              padding: const EdgeInsets.only(right: LedgerifySpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _selectedColorHex = colorHex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: colors.textPrimary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: _getContrastTextColor(color),
                        )
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LedgerifyColorScheme colors) {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(
                  color: colors.textTertiary.withValues(alpha: 0.5),
                  width: 1,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
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
        ),
        LedgerifySpacing.horizontalMd,
        // Save button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canSave ? _saveTag : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                disabledBackgroundColor: colors.surfaceHighlight,
                disabledForegroundColor: colors.textDisabled,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Save',
                style: LedgerifyTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _canSave ? colors.background : colors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns appropriate text color for contrast against a background color
  Color _getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }
}
