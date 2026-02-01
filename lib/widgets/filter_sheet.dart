import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../theme/ledgerify_theme.dart';

/// Filter state model for expense filtering.
///
/// Supports filtering by:
/// - Categories (empty set = all categories)
/// - Tags (empty set = all tags)
/// - Date range (start/end dates)
/// - Amount range (min/max amounts)
class ExpenseFilter {
  final Set<ExpenseCategory> categories;
  final Set<String> tagIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  const ExpenseFilter({
    this.categories = const {},
    this.tagIds = const {},
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  /// Returns true if any filter is active
  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      tagIds.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null;

  /// Returns the count of active filters
  int get activeFilterCount {
    int count = 0;
    if (categories.isNotEmpty) count++;
    if (tagIds.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  /// Creates a copy with optional field overrides
  ExpenseFilter copyWith({
    Set<ExpenseCategory>? categories,
    Set<String>? tagIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return ExpenseFilter(
      categories: categories ?? this.categories,
      tagIds: tagIds ?? this.tagIds,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  /// Empty filter (no filters applied)
  static const ExpenseFilter empty = ExpenseFilter();

  /// Checks if an expense matches this filter
  bool matches(Expense expense) {
    // Category filter
    if (categories.isNotEmpty && !categories.contains(expense.category)) {
      return false;
    }

    // Check tags (if any tag filter is set, expense must have at least one matching tag)
    if (tagIds.isNotEmpty) {
      final hasMatchingTag = expense.tagIds.any((id) => tagIds.contains(id));
      if (!hasMatchingTag) return false;
    }

    // Date range filter
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (expenseDate.isBefore(start)) {
        return false;
      }
    }
    if (endDate != null) {
      final end =
          DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
      if (expense.date.isAfter(end)) {
        return false;
      }
    }

    // Amount range filter
    if (minAmount != null && expense.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && expense.amount > maxAmount!) {
      return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseFilter &&
        _setEquals(other.categories, categories) &&
        _setEquals(other.tagIds, tagIds) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(categories),
      Object.hashAll(tagIds),
      startDate,
      endDate,
      minAmount,
      maxAmount,
    );
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// Filter Sheet - Ledgerify Design Language
///
/// A bottom sheet for filtering expenses by category, tags, date range, and amount.
/// Follows Quiet Finance design principles: calm, focused, minimal.
class FilterSheet extends StatefulWidget {
  final ExpenseFilter initialFilter;
  final TagService tagService;

  const FilterSheet({
    super.key,
    required this.initialFilter,
    required this.tagService,
  });

  /// Show as modal bottom sheet, returns updated filter or null if dismissed
  static Future<ExpenseFilter?> show(
    BuildContext context, {
    required ExpenseFilter initialFilter,
    required TagService tagService,
  }) {
    return showModalBottomSheet<ExpenseFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialFilter: initialFilter,
        tagService: tagService,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<ExpenseCategory> _selectedCategories;
  late Set<String> _selectedTagIds;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  final _dateFormat = DateFormat('MMM d, yyyy');

  late List<Tag> _allTags;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.initialFilter.categories);
    _selectedTagIds = Set.from(widget.initialFilter.tagIds);
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _minAmountController = TextEditingController(
      text: widget.initialFilter.minAmount?.toStringAsFixed(0) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialFilter.maxAmount?.toStringAsFixed(0) ?? '',
    );
    _allTags = widget.tagService.getAllTags();
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  ExpenseFilter get _currentFilter {
    final minText = _minAmountController.text.trim();
    final maxText = _maxAmountController.text.trim();

    return ExpenseFilter(
      categories: _selectedCategories,
      tagIds: _selectedTagIds,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: minText.isNotEmpty ? double.tryParse(minText) : null,
      maxAmount: maxText.isNotEmpty ? double.tryParse(maxText) : null,
    );
  }

  void _clearAll() {
    setState(() {
      _selectedCategories.clear();
      _selectedTagIds.clear();
      _startDate = null;
      _endDate = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilter() {
    Navigator.pop(context, _currentFilter);
  }

  void _toggleCategory(ExpenseCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _selectStartDate(LedgerifyColorScheme colors) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          _buildDatePickerTheme(context, child, colors),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate(LedgerifyColorScheme colors) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          _buildDatePickerTheme(context, child, colors),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Widget _buildDatePickerTheme(
    BuildContext context,
    Widget? child,
    LedgerifyColorScheme colors,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme(
          brightness: colors.brightness,
          primary: colors.accent,
          onPrimary: colors.background,
          secondary: colors.accent,
          onSecondary: colors.background,
          error: colors.negative,
          onError: Colors.white,
          surface: colors.surface,
          onSurface: colors.textPrimary,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colors.surface,
        ),
      ),
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.lg),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(colors),
              LedgerifySpacing.verticalXl,
              // Categories section
              _buildCategoriesSection(colors),
              LedgerifySpacing.verticalXl,
              // Tags section
              _buildTagsSection(colors),
              LedgerifySpacing.verticalXl,
              // Date range section
              _buildDateRangeSection(colors),
              LedgerifySpacing.verticalXl,
              // Amount range section
              _buildAmountRangeSection(colors),
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
          'Filter Expenses',
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

  Widget _buildCategoriesSection(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Wrap(
          spacing: LedgerifySpacing.sm,
          runSpacing: LedgerifySpacing.sm,
          children: ExpenseCategory.values.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return _buildCategoryChip(category, isSelected, colors);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    ExpenseCategory category,
    bool isSelected,
    LedgerifyColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () => _toggleCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? colors.background : colors.textSecondary,
            ),
            LedgerifySpacing.horizontalXs,
            Text(
              _getCategoryShortName(category),
              style: LedgerifyTypography.labelMedium.copyWith(
                color: isSelected ? colors.background : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              LedgerifySpacing.horizontalXs,
              Icon(
                Icons.check_rounded,
                size: 14,
                color: colors.background,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryShortName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Widget _buildTagsSection(LedgerifyColorScheme colors) {
    if (_allTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Wrap(
          spacing: LedgerifySpacing.sm,
          runSpacing: LedgerifySpacing.sm,
          children: _allTags.map((tag) {
            final isSelected = _selectedTagIds.contains(tag.id);
            return _buildTagChip(tag, isSelected, colors);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(
    Tag tag,
    bool isSelected,
    LedgerifyColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () => _toggleTag(tag.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? colors.background : tag.color,
                shape: BoxShape.circle,
              ),
            ),
            LedgerifySpacing.horizontalXs,
            Text(
              tag.name,
              style: LedgerifyTypography.labelMedium.copyWith(
                color: isSelected ? colors.background : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              LedgerifySpacing.horizontalXs,
              Icon(
                Icons.check_rounded,
                size: 14,
                color: colors.background,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                value: _startDate,
                onTap: () => _selectStartDate(colors),
                onClear: () => setState(() => _startDate = null),
                colors: colors,
              ),
            ),
            LedgerifySpacing.horizontalMd,
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                value: _endDate,
                onTap: () => _selectEndDate(colors),
                onClear: () => setState(() => _endDate = null),
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required LedgerifyColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.md,
          vertical: LedgerifySpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? _dateFormat.format(value) : 'Select',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color:
                      value != null ? colors.textPrimary : colors.textTertiary,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
              )
            else
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRangeSection(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Range',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        LedgerifySpacing.verticalSm,
        Row(
          children: [
            Expanded(
              child: _buildAmountField(
                controller: _minAmountController,
                hint: 'Min',
                colors: colors,
              ),
            ),
            LedgerifySpacing.horizontalMd,
            Expanded(
              child: _buildAmountField(
                controller: _maxAmountController,
                hint: 'Max',
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
    required LedgerifyColorScheme colors,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: LedgerifyTypography.bodyLarge.copyWith(
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText: '\u20B9 ',
        prefixStyle: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textSecondary,
        ),
        hintText: hint,
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
    );
  }

  Widget _buildActionButtons(LedgerifyColorScheme colors) {
    final hasFilters = _currentFilter.hasActiveFilters;

    return Row(
      children: [
        // Clear All button
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: hasFilters ? _clearAll : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(
                  color: hasFilters
                      ? colors.textTertiary.withValues(alpha: 0.5)
                      : colors.textDisabled.withValues(alpha: 0.3),
                  width: 1,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Clear All',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color:
                      hasFilters ? colors.textSecondary : colors.textDisabled,
                ),
              ),
            ),
          ),
        ),
        LedgerifySpacing.horizontalMd,
        // Apply button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Apply',
                style: LedgerifyTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.background,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
