import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/custom_category.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Represents the type of transaction.
enum TransactionType { income, expense }

/// A unified wrapper class for displaying both income and expense transactions
/// in a consistent format.
///
/// This abstraction allows the [UnifiedTransactionTile] widget to render
/// both transaction types with a unified visual design while preserving
/// access to the original data.
class UnifiedTransaction {
  /// Unique identifier for the transaction.
  final String id;

  /// The transaction amount (always positive).
  final double amount;

  /// Date when the transaction occurred.
  final DateTime date;

  /// Primary display text - merchant name for expenses, description for income.
  final String title;

  /// Secondary display text - category name for expenses, source name for income.
  final String subtitle;

  /// Icon to display in the tile.
  final IconData icon;

  /// Optional custom background color for the icon container.
  /// If null, default colors are used based on transaction type.
  final Color? iconBackgroundColor;

  /// The type of transaction (income or expense).
  final TransactionType type;

  /// Whether this transaction was generated from a recurring template.
  final bool isFromRecurring;

  /// Reference to the original Expense or Income object.
  /// Use this to access additional properties or for editing.
  final dynamic originalItem;

  const UnifiedTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconBackgroundColor,
    required this.type,
    required this.isFromRecurring,
    required this.originalItem,
  });

  /// Creates a [UnifiedTransaction] from an [Expense].
  ///
  /// If [customCategory] is provided and the expense uses a custom category,
  /// the custom category's name and icon will be used.
  factory UnifiedTransaction.fromExpense(
    Expense expense, {
    CustomCategory? customCategory,
  }) {
    // Determine title: merchant if available, otherwise category name
    String title;
    if (expense.merchant != null && expense.merchant!.isNotEmpty) {
      title = expense.merchant!;
    } else if (customCategory != null) {
      title = customCategory.name;
    } else {
      title = expense.category.displayName;
    }

    // Determine subtitle: category name if title was merchant, otherwise note
    String subtitle;
    final hasMerchant =
        expense.merchant != null && expense.merchant!.isNotEmpty;
    if (hasMerchant) {
      subtitle = customCategory?.name ?? expense.category.displayName;
    } else if (expense.note != null && expense.note!.isNotEmpty) {
      subtitle = expense.note!;
    } else {
      subtitle = customCategory?.name ?? expense.category.displayName;
    }

    // Use custom category icon if available, otherwise built-in category icon
    final icon = customCategory?.icon ?? expense.category.icon;

    return UnifiedTransaction(
      id: expense.id,
      amount: expense.amount,
      date: expense.date,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconBackgroundColor: customCategory?.color,
      type: TransactionType.expense,
      isFromRecurring: expense.isFromRecurring,
      originalItem: expense,
    );
  }

  /// Creates a [UnifiedTransaction] from an [Income].
  factory UnifiedTransaction.fromIncome(Income income) {
    // Determine title: description if available, otherwise source name
    String title;
    if (income.description != null && income.description!.isNotEmpty) {
      title = income.description!;
    } else {
      title = income.source.displayName;
    }

    // Subtitle is always the source name
    String subtitle;
    if (income.description != null && income.description!.isNotEmpty) {
      subtitle = income.source.displayName;
    } else {
      subtitle = '';
    }

    return UnifiedTransaction(
      id: income.id,
      amount: income.amount,
      date: income.date,
      title: title,
      subtitle: subtitle,
      icon: income.source.icon,
      iconBackgroundColor: null, // Use default accent color for income
      type: TransactionType.income,
      isFromRecurring: income.isFromRecurring,
      originalItem: income,
    );
  }

  /// Returns the original item cast as an [Expense].
  /// Throws if the transaction type is not expense.
  Expense get asExpense {
    if (type != TransactionType.expense) {
      throw StateError('Cannot cast income transaction to Expense');
    }
    return originalItem as Expense;
  }

  /// Returns the original item cast as an [Income].
  /// Throws if the transaction type is not income.
  Income get asIncome {
    if (type != TransactionType.income) {
      throw StateError('Cannot cast expense transaction to Income');
    }
    return originalItem as Income;
  }
}

/// Unified Transaction Tile - Ledgerify Design Language
///
/// Displays a single transaction (income or expense) with:
/// - Type indicator (filled circle for income, empty for expense)
/// - Category/source icon in styled container
/// - Title and subtitle with optional recurring indicator
/// - Amount in type-specific color (accent for income, neutral for expense)
/// - Relative date
/// - Swipe to delete action
class UnifiedTransactionTile extends StatelessWidget {
  /// The transaction to display.
  final UnifiedTransaction transaction;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Callback when the tile is swiped to delete.
  /// If null, swipe-to-delete is disabled.
  final VoidCallback? onDelete;

  const UnifiedTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  /// Formats the date for display.
  /// Returns "Today", "Yesterday", or "Jan 15" format.
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormatter.formatDayMonth(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final isIncome = transaction.type == TransactionType.income;

    // Determine icon container background
    final iconBgColor = transaction.iconBackgroundColor != null
        ? transaction.iconBackgroundColor!.withValues(alpha: 0.15)
        : isIncome
            ? colors.accentMuted
            : colors.surfaceHighlight;

    // Determine icon color
    final iconColor = transaction.iconBackgroundColor ??
        (isIncome ? colors.accent : colors.textSecondary);

    // Determine amount color
    final amountColor = isIncome ? colors.accent : colors.textPrimary;

    final Widget content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container with type indicator
            _buildIconContainer(colors, iconBgColor, iconColor, isIncome),

            LedgerifySpacing.horizontalMd,

            // Title, subtitle, and recurring indicator
            Expanded(
              child: _buildTextContent(colors),
            ),

            LedgerifySpacing.horizontalMd,

            // Amount and date
            _buildAmountSection(colors, amountColor, ''),
          ],
        ),
      ),
    );

    // Wrap with Dismissible if onDelete is provided
    if (onDelete != null) {
      return RepaintBoundary(
        child: Dismissible(
          key: ValueKey(transaction.id),
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
            onDelete!();
            return false; // We handle deletion in the callback
          },
          child: content,
        ),
      );
    }

    return RepaintBoundary(child: content);
  }

  /// Builds the icon container with type indicator.
  Widget _buildIconContainer(
    LedgerifyColorScheme colors,
    Color bgColor,
    Color iconColor,
    bool isIncome,
  ) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          // Main icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Icon(
              transaction.icon,
              size: 24,
              color: iconColor,
            ),
          ),
          // Type indicator (top-left corner)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isIncome ? colors.accent : colors.background,
                border: isIncome
                    ? null
                    : Border.all(color: colors.textTertiary, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the title, subtitle, and recurring indicator.
  Widget _buildTextContent(LedgerifyColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          transaction.title,
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Subtitle row with recurring indicator
        if (transaction.subtitle.isNotEmpty || transaction.isFromRecurring)
          Row(
            children: [
              if (transaction.subtitle.isNotEmpty)
                Flexible(
                  child: Text(
                    transaction.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LedgerifyTypography.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              if (transaction.isFromRecurring) ...[
                if (transaction.subtitle.isNotEmpty)
                  LedgerifySpacing.horizontalXs,
                Icon(
                  Icons.repeat_rounded,
                  size: 14,
                  color: colors.textTertiary,
                ),
              ],
            ],
          ),
      ],
    );
  }

  /// Builds the amount and date section.
  Widget _buildAmountSection(
    LedgerifyColorScheme colors,
    Color amountColor,
    String prefix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount
        Text(
          '$prefix${CurrencyFormatter.format(transaction.amount)}',
          style: LedgerifyTypography.amountMedium.copyWith(
            color: amountColor,
          ),
        ),
        LedgerifySpacing.verticalXs,
        // Date
        Text(
          _formatDate(transaction.date),
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
