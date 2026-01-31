import 'package:flutter/material.dart';

/// Ledgerify Color System
///
/// A calm, premium color palette based on deep charcoal tones
/// with pistachio accent for positive actions and semantic meaning.
///
/// Philosophy: "Quiet Finance" — trustworthy, weighty, calming
class LedgerifyColors {
  LedgerifyColors._();

  // ============================================
  // BASE PALETTE
  // ============================================

  /// Primary app background - deep charcoal (never pure black)
  static const Color background = Color(0xFF121212);

  /// Cards and containers
  static const Color surface = Color(0xFF1E1E1E);

  /// Elevated cards, modals, dialogs
  static const Color surfaceElevated = Color(0xFF252525);

  /// Hover states, selections, input fields
  static const Color surfaceHighlight = Color(0xFF2C2C2C);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Headlines, amounts, key data - full white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Labels, descriptions - 70% white
  static const Color textSecondary = Color(0xB3FFFFFF);

  /// Metadata, timestamps, hints - 50% white
  static const Color textTertiary = Color(0x80FFFFFF);

  /// Disabled states - 30% white
  static const Color textDisabled = Color(0x4DFFFFFF);

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// Primary accent - soft pistachio green
  /// Used for: primary actions, positive values, progress
  static const Color accent = Color(0xFFA8E6CF);

  /// Muted accent for backgrounds - 15% opacity
  static const Color accentMuted = Color(0x26A8E6CF);

  /// Accent with darker tone for pressed states
  static const Color accentPressed = Color(0xFF8BD4B8);

  /// Negative values only - soft coral
  static const Color negative = Color(0xFFFF6B6B);

  /// Muted negative for backgrounds - 15% opacity
  static const Color negativeMuted = Color(0x26FF6B6B);

  /// Warning color (use sparingly)
  static const Color warning = Color(0xFFFFB347);

  /// Warning muted for backgrounds - 15% opacity
  static const Color warningMuted = Color(0x26FFB347);

  // ============================================
  // UTILITY COLORS
  // ============================================

  /// Divider color - very subtle
  static const Color divider = Color(0x1AFFFFFF); // 10% white

  /// Shadow color for elevation
  static const Color shadow = Color(0x4D000000); // 30% black

  /// Overlay for modals/dialogs
  static const Color overlay = Color(0x80000000); // 50% black

  // ============================================
  // CATEGORY COLORS (for expense categories)
  // ============================================

  /// Subtle, muted category colors that don't compete with accent
  static const Color categoryFood = Color(0xFF6B8E7B);
  static const Color categoryTransport = Color(0xFF7B8E9E);
  static const Color categoryShopping = Color(0xFF9E8E7B);
  static const Color categoryEntertainment = Color(0xFF8E7B9E);
  static const Color categoryBills = Color(0xFF7B9E8E);
  static const Color categoryHealth = Color(0xFF9E7B7B);
  static const Color categoryEducation = Color(0xFF7B7B9E);
  static const Color categoryOther = Color(0xFF8E8E8E);

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Returns the appropriate text color for an amount
  /// Positive: accent, Negative: negative, Zero: textSecondary
  static Color amountColor(double amount) {
    if (amount > 0) return accent;
    if (amount < 0) return negative;
    return textSecondary;
  }

  /// Returns color with custom opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
