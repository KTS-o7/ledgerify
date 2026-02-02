import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_template.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Actions available from the quick add sheet
enum QuickAddAction {
  expense,
  income,
  goal,
}

/// Result from the quick add sheet.
/// Either an action to navigate to, or a template that was used to create an expense.
class QuickAddResult {
  /// The action selected (if navigating to a form)
  final QuickAddAction? action;

  /// Whether a template was used to create an expense directly
  final bool templateUsed;

  /// The expense created from a template (if any)
  final Expense? createdExpense;

  const QuickAddResult.action(this.action)
      : templateUsed = false,
        createdExpense = null;

  const QuickAddResult.template(this.createdExpense)
      : action = null,
        templateUsed = true;
}

/// A bottom sheet for quickly adding expenses, income, or goals.
///
/// Follows Quiet Finance design principles:
/// - Clean, minimal UI
/// - No emoji, just icons
/// - Subtle tap feedback
///
/// Shows frequent expense templates at the top for 1-tap expense creation.
class QuickAddSheet extends StatelessWidget {
  final ExpenseService? expenseService;

  const QuickAddSheet({
    super.key,
    this.expenseService,
  });

  /// Shows the quick add sheet and returns the selected action or template result.
  ///
  /// Returns `null` if dismissed without selection.
  static Future<QuickAddAction?> show(
    BuildContext context, {
    ExpenseService? expenseService,
  }) async {
    final result = await showModalBottomSheet<QuickAddResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickAddSheet(expenseService: expenseService),
    );

    if (result == null) return null;

    // If template was used, return expense action (the expense was already created)
    if (result.templateUsed) {
      // Return null since we already handled the expense creation
      return null;
    }

    return result.action;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    // Get templates if expense service is available
    final templates =
        expenseService?.getFrequentTemplates(limit: 3) ?? <ExpenseTemplate>[];

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

              // Quick Add Templates Section (if available)
              if (templates.isNotEmpty) ...[
                _TemplatesSection(
                  templates: templates,
                  expenseService: expenseService!,
                ),
                const SizedBox(height: LedgerifySpacing.xl),
              ],

              // Action tiles
              _QuickAddTile(
                icon: Icons.payments_rounded,
                iconColor: colors.negative,
                title: 'Add Expense',
                subtitle: 'Track money going out',
                onTap: () => Navigator.pop(
                  context,
                  const QuickAddResult.action(QuickAddAction.expense),
                ),
              ),
              const SizedBox(height: LedgerifySpacing.md),

              _QuickAddTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: colors.accent,
                title: 'Add Income',
                subtitle: 'Track money coming in',
                onTap: () => Navigator.pop(
                  context,
                  const QuickAddResult.action(QuickAddAction.income),
                ),
              ),
              const SizedBox(height: LedgerifySpacing.md),

              _QuickAddTile(
                icon: Icons.flag_rounded,
                iconColor: colors.warning,
                title: 'Add Goal',
                subtitle: 'Set a savings target',
                onTap: () => Navigator.pop(
                  context,
                  const QuickAddResult.action(QuickAddAction.goal),
                ),
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

/// Section showing quick add templates as horizontal scrollable chips.
class _TemplatesSection extends StatelessWidget {
  final List<ExpenseTemplate> templates;
  final ExpenseService expenseService;

  const _TemplatesSection({
    required this.templates,
    required this.expenseService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Quick Add',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: LedgerifySpacing.md),

        // Horizontal scrollable template chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: templates.asMap().entries.map((entry) {
              final index = entry.key;
              final template = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < templates.length - 1 ? LedgerifySpacing.sm : 0,
                ),
                child: _TemplateChip(
                  template: template,
                  onTap: () => _useTemplate(context, template),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _useTemplate(
      BuildContext context, ExpenseTemplate template) async {
    final colors = LedgerifyColors.of(context);

    // Create expense immediately with template defaults
    final expense = await expenseService.addExpense(
      amount: template.amount ?? 0,
      category: template.category,
      date: DateTime.now(),
      merchant: template.merchant,
      source: ExpenseSource.manual,
    );

    if (!context.mounted) return;

    // Close sheet and show confirmation
    Navigator.pop(context, QuickAddResult.template(expense));

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${template.displayTitle} - ${CurrencyFormatter.format(template.amount ?? 0)} added',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// A chip displaying a template for quick add.
class _TemplateChip extends StatelessWidget {
  final ExpenseTemplate template;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Material(
      color: colors.surfaceHighlight,
      borderRadius: LedgerifyRadius.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: LedgerifyRadius.borderRadiusMd,
        splashColor: colors.accentMuted,
        highlightColor: colors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.md,
            vertical: LedgerifySpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category icon
              Icon(
                template.category.icon,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: LedgerifySpacing.sm),

              // Title and amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Merchant or category name
                  Text(
                    _truncateTitle(template.displayTitle),
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Amount
                  if (template.hasAmount)
                    Text(
                      CurrencyFormatter.format(template.amount!),
                      style: LedgerifyTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Truncates title to fit in chip (max 12 characters)
  String _truncateTitle(String title) {
    if (title.length <= 12) return title;
    return '${title.substring(0, 10)}...';
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
