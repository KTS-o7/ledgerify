import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/custom_category.dart';
import '../services/custom_category_service.dart';
import '../theme/ledgerify_theme.dart';

/// Category Management Screen - Ledgerify Design Language
///
/// A screen for managing custom expense categories.
/// Features:
/// - List of custom categories with icon, name, and active toggle
/// - FAB to add new category
/// - Swipe to delete
/// - Tap to edit
/// - Add/Edit bottom sheet with icon and color pickers
class CategoryManagementScreen extends StatelessWidget {
  final CustomCategoryService categoryService;

  const CategoryManagementScreen({
    super.key,
    required this.categoryService,
  });

  /// Available icons for custom categories
  static const List<IconData> _iconOptions = [
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.coffee_rounded,
    Icons.flight_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.child_care_rounded,
    Icons.savings_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_gas_station_rounded,
    Icons.wifi_rounded,
    Icons.phone_android_rounded,
    Icons.subscriptions_rounded,
    Icons.spa_rounded,
    Icons.checkroom_rounded,
    Icons.local_grocery_store_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.book_rounded,
    Icons.camera_alt_rounded,
  ];

  /// Available color options (hex strings for storage)
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: colors.textPrimary,
        ),
        title: Text(
          'Custom Categories',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: ValueListenableBuilder<Box<CustomCategory>>(
        valueListenable: categoryService.box.listenable(),
        builder: (context, box, _) {
          final categories = categoryService.getAllCategories();

          if (categories.isEmpty) {
            return _EmptyState(colors: colors);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryListItem(
                category: category,
                colors: colors,
                onTap: () => _showEditBottomSheet(context, category),
                onToggleActive: () => categoryService.toggleActive(category.id),
                onDelete: () => _deleteCategory(context, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_custom_categories',
        onPressed: () => _showAddBottomSheet(context),
        backgroundColor: colors.accent,
        foregroundColor: colors.background,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryBottomSheet(
        categoryService: categoryService,
        iconOptions: _iconOptions,
        colorOptionsHex: _colorOptionsHex,
        colorOptions: _colorOptions,
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, CustomCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryBottomSheet(
        categoryService: categoryService,
        iconOptions: _iconOptions,
        colorOptionsHex: _colorOptionsHex,
        colorOptions: _colorOptions,
        categoryToEdit: category,
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    CustomCategory category,
  ) async {
    await categoryService.deleteCategory(category.id);

    if (context.mounted) {
      final colors = LedgerifyColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.name} deleted',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Empty state when no custom categories exist
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
              Icons.category_outlined,
              size: 64,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No custom categories yet',
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Tap + to create one',
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

/// Individual category list item with swipe to delete
class _CategoryListItem extends StatelessWidget {
  final CustomCategory category;
  final LedgerifyColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _CategoryListItem({
    required this.category,
    required this.colors,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LedgerifySpacing.sm),
      child: Dismissible(
        key: Key(category.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.negative,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: LedgerifyRadius.borderRadiusLg,
          child: Container(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: LedgerifyRadius.borderRadiusLg,
            ),
            child: Row(
              children: [
                // Icon with category color
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
                LedgerifySpacing.horizontalMd,
                // Name
                Expanded(
                  child: Text(
                    category.name,
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                // Active toggle
                Switch(
                  value: category.isActive,
                  onChanged: (_) => onToggleActive(),
                  activeThumbColor: colors.accent,
                  activeTrackColor: colors.accentMuted,
                  inactiveThumbColor: colors.textTertiary,
                  inactiveTrackColor: colors.surfaceHighlight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for adding or editing a category
class _CategoryBottomSheet extends StatefulWidget {
  final CustomCategoryService categoryService;
  final List<IconData> iconOptions;
  final List<String> colorOptionsHex;
  final List<Color> colorOptions;
  final CustomCategory? categoryToEdit;

  const _CategoryBottomSheet({
    required this.categoryService,
    required this.iconOptions,
    required this.colorOptionsHex,
    required this.colorOptions,
    this.categoryToEdit,
  });

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  late TextEditingController _nameController;
  late int _selectedIconCodePoint;
  late String _selectedColorHex;
  bool _isLoading = false;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final category = widget.categoryToEdit!;
      _nameController = TextEditingController(text: category.name);
      _selectedIconCodePoint = category.iconCodePoint;
      _selectedColorHex = category.colorHex;
    } else {
      _nameController = TextEditingController();
      _selectedIconCodePoint = widget.iconOptions.first.codePoint;
      _selectedColorHex = widget.colorOptionsHex.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColorHex(String hex) {
    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;

    // Use efficient exists check
    if (widget.categoryService.categoryExists(name)) {
      // Allow same name if editing the same category
      if (_isEditing &&
          widget.categoryToEdit!.name.toLowerCase() == name.toLowerCase()) {
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> _saveCategory() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();

      if (_isEditing) {
        final updated = widget.categoryToEdit!.copyWith(
          name: name,
          iconCodePoint: _selectedIconCodePoint,
          colorHex: _selectedColorHex,
        );
        await widget.categoryService.updateCategory(updated);
      } else {
        await widget.categoryService.createCategory(
          name: name,
          iconCodePoint: _selectedIconCodePoint,
          colorHex: _selectedColorHex,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final colors = LedgerifyColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving category: $e',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
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
                _isEditing ? 'Edit Category' : 'New Category',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              LedgerifySpacing.verticalXl,

              // Name field
              _buildNameField(colors),
              LedgerifySpacing.verticalXl,

              // Icon picker
              _buildIconPicker(colors),
              LedgerifySpacing.verticalXl,

              // Color picker
              _buildColorPicker(colors),
              LedgerifySpacing.verticalXl,

              // Action buttons
              _buildActionButtons(colors),
              LedgerifySpacing.verticalSm,
            ],
          ),
        ),
      ),
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
          textCapitalization: TextCapitalization.words,
          autofocus: !_isEditing,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Category name',
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
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.lg,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildIconPicker(LedgerifyColorScheme colors) {
    // Cache the selected color once, instead of parsing on every grid item
    final selectedColorIndex =
        widget.colorOptionsHex.indexOf(_selectedColorHex);
    final selectedColor = selectedColorIndex >= 0
        ? widget.colorOptions[selectedColorIndex]
        : _parseColorHex(_selectedColorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: LedgerifySpacing.sm,
            mainAxisSpacing: LedgerifySpacing.sm,
          ),
          itemCount: widget.iconOptions.length,
          itemBuilder: (context, index) {
            final icon = widget.iconOptions[index];
            final isSelected = icon.codePoint == _selectedIconCodePoint;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIconCodePoint = icon.codePoint;
                });
              },
              borderRadius: LedgerifyRadius.borderRadiusMd,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.15)
                      : colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  border: isSelected
                      ? Border.all(color: selectedColor, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : colors.textSecondary,
                  size: 24,
                ),
              ),
            );
          },
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.colorOptions.length, (index) {
            final colorHex = widget.colorOptionsHex[index];
            final color = widget.colorOptions[index];
            final isSelected = colorHex == _selectedColorHex;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedColorHex = colorHex;
                });
              },
              borderRadius: LedgerifyRadius.borderRadiusFull,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: colors.textPrimary,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
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
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(
                vertical: LedgerifySpacing.lg,
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
        LedgerifySpacing.horizontalMd,
        // Save button
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading || !_isFormValid ? null : _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.background,
              disabledBackgroundColor: colors.surfaceHighlight,
              disabledForegroundColor: colors.textDisabled,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: LedgerifySpacing.lg,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: LedgerifyRadius.borderRadiusMd,
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.textDisabled,
                      ),
                    ),
                  )
                : Text(
                    'Save',
                    style: LedgerifyTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isFormValid
                          ? colors.background
                          : colors.textDisabled,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
