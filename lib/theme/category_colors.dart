import 'package:flutter/material.dart';
import '../models/expense.dart';

/// Extension providing theme-aware colors for expense categories.
///
/// Colors are muted and professional, following the Quiet Finance philosophy.
/// Dark theme uses lighter, more visible shades.
/// Light theme uses deeper, more saturated shades.
///
/// Usage:
/// ```dart
/// final color = ExpenseCategory.food.color(context);
/// ```
extension ExpenseCategoryColor on ExpenseCategory {
  /// Returns the category color appropriate for the current theme.
  Color color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ExpenseCategory.food:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case ExpenseCategory.transport:
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
      case ExpenseCategory.shopping:
        return isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2);
      case ExpenseCategory.entertainment:
        return isDark ? const Color(0xFFFF7043) : const Color(0xFFE64A19);
      case ExpenseCategory.bills:
        return isDark ? const Color(0xFF78909C) : const Color(0xFF546E7A);
      case ExpenseCategory.health:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
      case ExpenseCategory.education:
        return isDark ? const Color(0xFF5C6BC0) : const Color(0xFF3949AB);
      case ExpenseCategory.other:
        return isDark ? const Color(0xFF8D6E63) : const Color(0xFF5D4037);
    }
  }
}
