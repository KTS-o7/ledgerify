import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Expense List Tile - Ledgerify Design Language
///
/// Displays a single expense entry with:
/// - Category icon in rounded container
/// - Category name and optional note
/// - Amount and relative date
/// - Swipe to delete action
class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: LedgerifySpacing.xl),
        color: colors.negative,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion in the callback
      },
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.md,
          ),
          child: Row(
            children: [
              // Category icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
                child: Icon(
                  expense.category.icon,
                  size: 24,
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(width: LedgerifySpacing.md),

              // Category name and note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category.displayName,
                      style: LedgerifyTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Text(
                        expense.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(width: LedgerifySpacing.md),

              // Amount and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(expense.amount),
                    style: LedgerifyTypography.amountMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: LedgerifySpacing.xs),
                  Text(
                    DateFormatter.formatRelative(expense.date),
                    style: LedgerifyTypography.bodySmall.copyWith(
                      color: colors.textTertiary,
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
}
