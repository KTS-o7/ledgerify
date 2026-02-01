import 'package:flutter/material.dart';
import 'colors.dart';

/// Ledgerify Typography System
///
/// Numbers dominate; labels whisper.
/// Large balances and totals are visual anchors.
/// Labels and metadata are smaller and lower contrast.
///
/// Philosophy: Reduce opacity before reducing font size
class LedgerifyTypography {
  LedgerifyTypography._();

  // ============================================
  // FONT FAMILY
  // ============================================

  /// Primary font family
  /// Uses system default (SF Pro on iOS, Roboto on Android)
  /// For custom font, change to 'Inter'
  static const String fontFamily = 'Roboto';

  // ============================================
  // DISPLAY STYLES (Hero numbers, totals)
  // ============================================

  /// 48sp - Hero amounts (₹1,23,456)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: LedgerifyColors.textPrimary,
  );

  /// 36sp - Section totals
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.25,
    color: LedgerifyColors.textPrimary,
  );

  /// 28sp - Card headlines
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
    color: LedgerifyColors.textPrimary,
  );

  // ============================================
  // HEADLINE STYLES (Titles)
  // ============================================

  /// 24sp - Screen titles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
    color: LedgerifyColors.textPrimary,
  );

  /// 20sp - Card titles
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: LedgerifyColors.textPrimary,
  );

  /// 18sp - Subsection titles
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
    color: LedgerifyColors.textPrimary,
  );

  // ============================================
  // BODY STYLES (Content text)
  // ============================================

  /// 16sp - Primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: LedgerifyColors.textPrimary,
  );

  /// 14sp - Secondary text, descriptions
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: LedgerifyColors.textSecondary,
  );

  /// 12sp - Captions, metadata
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
    color: LedgerifyColors.textTertiary,
  );

  // ============================================
  // LABEL STYLES (UI elements)
  // ============================================

  /// 14sp - Button labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: LedgerifyColors.textPrimary,
  );

  /// 12sp - Tabs, chips
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
    color: LedgerifyColors.textSecondary,
  );

  /// 10sp - Badges, tiny labels
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
    color: LedgerifyColors.textTertiary,
  );

  // ============================================
  // AMOUNT STYLES (Numbers with semantic color)
  // ============================================

  /// Large amount (hero) - for main balance display
  static const TextStyle amountHero = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.textPrimary,
  );

  /// Large amount - for card totals
  static const TextStyle amountLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.textPrimary,
  );

  /// Medium amount - for list items
  static const TextStyle amountMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.textPrimary,
  );

  /// Small amount - for secondary displays
  static const TextStyle amountSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.textSecondary,
  );

  // ============================================
  // DELTA STYLES (Change indicators)
  // ============================================

  /// Positive delta style (+12.5%)
  static const TextStyle deltaPositive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.accent,
  );

  /// Negative delta style (−8.3%)
  static const TextStyle deltaNegative = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.negative,
  );

  /// Neutral delta style (0%)
  static const TextStyle deltaNeutral = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: LedgerifyColors.textSecondary,
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Returns the appropriate delta style based on value
  static TextStyle getDeltaStyle(double value) {
    if (value > 0) return deltaPositive;
    if (value < 0) return deltaNegative;
    return deltaNeutral;
  }

  /// Creates a style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Creates a style with secondary color
  static TextStyle asSecondary(TextStyle style) {
    return style.copyWith(color: LedgerifyColors.textSecondary);
  }

  /// Creates a style with tertiary color
  static TextStyle asTertiary(TextStyle style) {
    return style.copyWith(color: LedgerifyColors.textTertiary);
  }

  /// Creates a style with accent color
  static TextStyle asAccent(TextStyle style) {
    return style.copyWith(color: LedgerifyColors.accent);
  }

  /// Creates a style with negative color
  static TextStyle asNegative(TextStyle style) {
    return style.copyWith(color: LedgerifyColors.negative);
  }
}
