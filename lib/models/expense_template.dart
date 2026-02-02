import 'expense.dart';

/// Represents a template for quick expense entry based on frequent patterns.
///
/// Templates are generated from analyzing recent expenses and grouping
/// by merchant+category combination to identify frequent spending patterns.
class ExpenseTemplate {
  /// Optional merchant name (e.g., "Starbucks", "Uber")
  final String? merchant;

  /// Average amount for this template (calculated from recent expenses)
  final double? amount;

  /// Category for this template
  final ExpenseCategory category;

  /// Number of times this pattern has been used
  final int usageCount;

  const ExpenseTemplate({
    this.merchant,
    this.amount,
    required this.category,
    required this.usageCount,
  });

  /// Returns a display-friendly title for the template.
  /// Uses merchant name if available, otherwise falls back to category.
  String get displayTitle {
    if (merchant != null && merchant!.isNotEmpty) {
      return merchant!;
    }
    return category.displayName;
  }

  /// Whether this template has a specific merchant.
  bool get hasMerchant => merchant != null && merchant!.isNotEmpty;

  /// Whether this template has an amount.
  bool get hasAmount => amount != null && amount! > 0;

  @override
  String toString() {
    return 'ExpenseTemplate(merchant: $merchant, amount: $amount, category: ${category.displayName}, usageCount: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseTemplate &&
        other.merchant == merchant &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(merchant, category);
}
