import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';

/// Actions available from the quick add sheet
enum QuickAddAction {
  expense,
  income,
  goal,
}

/// A bottom sheet for quickly adding expenses, income, or goals.
///
/// Follows Quiet Finance design principles:
/// - Clean, minimal UI
/// - No emoji, just icons
/// - Subtle tap feedback
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  /// Shows the quick add sheet and returns the selected action.
  ///
  /// Returns `null` if dismissed without selection.
  static Future<QuickAddAction?> show(BuildContext context) {
    return showModalBottomSheet<QuickAddAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: LedgerifySpacing.lg,
            right: LedgerifySpacing.lg,
            top: LedgerifySpacing.md,
            bottom: LedgerifySpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _buildDragHandle(colors),
              const SizedBox(height: LedgerifySpacing.lg),

              // Title
              Text(
                'Add New',
                style: LedgerifyTypography.headlineMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: LedgerifySpacing.xl),

              // Action tiles
              _QuickAddTile(
                icon: Icons.payments_rounded,
                iconColor: colors.negative,
                title: 'Add Expense',
                subtitle: 'Track money going out',
                onTap: () => Navigator.pop(context, QuickAddAction.expense),
              ),
              const SizedBox(height: LedgerifySpacing.md),

              _QuickAddTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: colors.accent,
                title: 'Add Income',
                subtitle: 'Track money coming in',
                onTap: () => Navigator.pop(context, QuickAddAction.income),
              ),
              const SizedBox(height: LedgerifySpacing.md),

              _QuickAddTile(
                icon: Icons.flag_rounded,
                iconColor: colors.warning,
                title: 'Add Goal',
                subtitle: 'Set a savings target',
                onTap: () => Navigator.pop(context, QuickAddAction.goal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(LedgerifyColorScheme colors) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: colors.textTertiary,
        borderRadius: LedgerifyRadius.borderRadiusFull,
      ),
    );
  }
}

/// A tappable tile for quick add actions.
class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Material(
      color: colors.surface,
      borderRadius: LedgerifyRadius.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: LedgerifyRadius.borderRadiusLg,
        splashColor: colors.accentMuted,
        highlightColor: colors.surfaceHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.lg,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: LedgerifySpacing.lg),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LedgerifyTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: LedgerifySpacing.xs),
                    Text(
                      subtitle,
                      style: LedgerifyTypography.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
