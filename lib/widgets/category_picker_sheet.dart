import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/custom_category.dart';
import '../services/custom_category_service.dart';
import '../theme/ledgerify_theme.dart';

/// Represents a category selection result.
/// Either [builtInCategory] or [customCategoryId] will be non-null.
class CategorySelection {
  final ExpenseCategory? builtInCategory;
  final String? customCategoryId;

  const CategorySelection({
    this.builtInCategory,
    this.customCategoryId,
  });

  /// Whether this selection is a built-in category.
  bool get isBuiltIn => builtInCategory != null;

  /// Whether this selection is a custom category.
  bool get isCustom => customCategoryId != null;
}

/// Category Picker Sheet - Ledgerify Design Language
///
/// A bottom sheet for selecting expense categories (built-in + custom).
/// Features:
/// - Drag handle for intuitive dismissal
/// - Grid layout with 2 columns
/// - Section headers for built-in and custom categories
/// - Visual selection state with accent border
class CategoryPickerSheet extends StatefulWidget {
  final CustomCategoryService customCategoryService;
  final ExpenseCategory? selectedBuiltIn;
  final String? selectedCustomId;

  const CategoryPickerSheet({
    super.key,
    required this.customCategoryService,
    this.selectedBuiltIn,
    this.selectedCustomId,
  });

  /// Show as modal bottom sheet
  static Future<CategorySelection?> show(
    BuildContext context, {
    required CustomCategoryService customCategoryService,
    ExpenseCategory? selectedBuiltIn,
    String? selectedCustomId,
  }) {
    return showModalBottomSheet<CategorySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerSheet(
        customCategoryService: customCategoryService,
        selectedBuiltIn: selectedBuiltIn,
        selectedCustomId: selectedCustomId,
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late List<CustomCategory> _customCategories;

  @override
  void initState() {
    super.initState();
    _customCategories = widget.customCategoryService.getActiveCategories();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            _buildDragHandle(colors),
            // Header
            _buildHeader(colors, context),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Built-in categories section
                    _buildSectionHeader('Built-in Categories', colors),
                    LedgerifySpacing.verticalMd,
                    _buildBuiltInGrid(colors, context),
                    // Custom categories section (if any exist)
                    if (_customCategories.isNotEmpty) ...[
                      LedgerifySpacing.verticalXl,
                      _buildSectionHeader('Custom Categories', colors),
                      LedgerifySpacing.verticalMd,
                      _buildCustomGrid(_customCategories, colors, context),
                    ],
                    LedgerifySpacing.verticalLg,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(LedgerifyColorScheme colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: LedgerifySpacing.md),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.textTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(LedgerifyColorScheme colors, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Category',
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, LedgerifyColorScheme colors) {
    return Text(
      title,
      style: LedgerifyTypography.labelMedium.copyWith(
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildBuiltInGrid(LedgerifyColorScheme colors, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: LedgerifySpacing.sm,
        crossAxisSpacing: LedgerifySpacing.sm,
        childAspectRatio: 1.4,
      ),
      itemCount: ExpenseCategory.values.length,
      itemBuilder: (context, index) {
        final category = ExpenseCategory.values[index];
        final isSelected = widget.selectedBuiltIn == category &&
            widget.selectedCustomId == null;

        return _CategoryGridItem(
          icon: category.icon,
          name: category.displayName,
          color: colors.accent,
          isSelected: isSelected,
          onTap: () {
            Navigator.pop(
              context,
              CategorySelection(builtInCategory: category),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomGrid(
    List<CustomCategory> categories,
    LedgerifyColorScheme colors,
    BuildContext context,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: LedgerifySpacing.sm,
        crossAxisSpacing: LedgerifySpacing.sm,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = widget.selectedCustomId == category.id;

        return _CategoryGridItem(
          icon: category.icon,
          name: category.name,
          color: category.color,
          isSelected: isSelected,
          onTap: () {
            Navigator.pop(
              context,
              CategorySelection(customCategoryId: category.id),
            );
          },
        );
      },
    );
  }
}

/// Individual category grid item widget.
class _CategoryGridItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridItem({
    required this.icon,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(LedgerifySpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? colors.accent : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with optional checkmark overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: color,
                  ),
                ),
                // Checkmark for selected state
                if (isSelected)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: colors.background,
                      ),
                    ),
                  ),
              ],
            ),
            LedgerifySpacing.verticalSm,
            // Category name
            Text(
              name,
              style: LedgerifyTypography.labelMedium.copyWith(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
