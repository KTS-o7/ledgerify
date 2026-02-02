import 'package:flutter/material.dart';
import '../models/income.dart';
import '../theme/ledgerify_theme.dart';

/// Income Source Picker Sheet - Ledgerify Design Language
///
/// A bottom sheet for selecting income source when confirming credit SMS transactions.
/// Features:
/// - Drag handle for intuitive dismissal
/// - Grid layout with 3 columns
/// - Visual selection state with accent border
class IncomeSourcePickerSheet extends StatelessWidget {
  final IncomeSource? selectedSource;

  const IncomeSourcePickerSheet({
    super.key,
    this.selectedSource,
  });

  /// Show as modal bottom sheet
  static Future<IncomeSource?> show(
    BuildContext context, {
    IncomeSource? selectedSource,
  }) {
    return showModalBottomSheet<IncomeSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeSourcePickerSheet(
        selectedSource: selectedSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
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
            // Grid content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
              ),
              child: _buildSourceGrid(colors, context),
            ),
            const SizedBox(height: LedgerifySpacing.lg),
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
            'Select Source',
            style: LedgerifyTypography.headlineSmall.copyWith(
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

  Widget _buildSourceGrid(LedgerifyColorScheme colors, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: LedgerifySpacing.sm,
        crossAxisSpacing: LedgerifySpacing.sm,
        childAspectRatio: 0.95,
      ),
      itemCount: IncomeSource.values.length,
      itemBuilder: (context, index) {
        final source = IncomeSource.values[index];
        final isSelected = selectedSource == source;

        return _SourceGridItem(
          icon: source.icon,
          name: source.displayName,
          isSelected: isSelected,
          onTap: () => Navigator.pop(context, source),
        );
      },
    );
  }
}

/// Individual source grid item widget.
class _SourceGridItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceGridItem({
    required this.icon,
    required this.name,
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
        padding: const EdgeInsets.all(LedgerifySpacing.sm),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colors.accent,
                  ),
                ),
                // Checkmark for selected state
                if (isSelected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: colors.background,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: LedgerifySpacing.xs),
            // Source name
            Text(
              name,
              style: LedgerifyTypography.labelMedium.copyWith(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
