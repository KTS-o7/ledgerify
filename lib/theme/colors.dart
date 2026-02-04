import 'package:flutter/material.dart';

/// Ledgerify Color System
///
/// A calm, premium color palette for both dark and light modes.
/// Philosophy: "Quiet Finance" — trustworthy, weighty, calming
///
/// Usage:
/// - Use `LedgerifyColors.dark` for dark theme colors
/// - Use `LedgerifyColors.light` for light theme colors
/// - Use `LedgerifyColors.of(context)` to get current theme colors
class LedgerifyColors {
  LedgerifyColors._();

  // ============================================
  // DARK THEME COLORS
  // ============================================
  static const LedgerifyColorScheme dark = LedgerifyColorScheme(
    brightness: Brightness.dark,
    // Base palette
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceElevated: Color(0xFF252525),
    surfaceHighlight: Color(0xFF2C2C2C),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF), // 70%
    textTertiary: Color(0x80FFFFFF), // 50%
    textDisabled: Color(0x4DFFFFFF), // 30%
    // Semantic colors
    accent: Color(0xFFA8E6CF),
    accentMuted: Color(0x26A8E6CF), // 15%
    accentPressed: Color(0xFF8BD4B8),
    negative: Color(0xFFFF6B6B),
    negativeMuted: Color(0x26FF6B6B),
    warning: Color(0xFFFFB347),
    warningMuted: Color(0x26FFB347),
    // Utility
    divider: Color(0x1AFFFFFF), // 10%
    shadow: Color(0x4D000000), // 30%
    overlay: Color(0x80000000), // 50%
  );

  // ============================================
  // LIGHT THEME COLORS
  // ============================================
  static const LedgerifyColorScheme light = LedgerifyColorScheme(
    brightness: Brightness.light,
    // Base palette - warm off-whites, no pure white backgrounds
    background: Color(0xFFF5F5F3), // Warm off-white
    surface: Color(0xFFFFFFFF), // White cards
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceHighlight: Color(0xFFEBEBEA), // Warm gray
    // Text colors - near black, not pure black
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xB31A1A1A), // 70%
    textTertiary: Color(0x731A1A1A), // 45%
    textDisabled: Color(0x4D1A1A1A), // 30%
    // Semantic colors - darker for contrast on light backgrounds
    accent: Color(0xFF2E9E6B), // Darker pistachio
    accentMuted: Color(0x1F2E9E6B), // 12%
    accentPressed: Color(0xFF258556),
    negative: Color(0xFFDC4444), // Darker red
    negativeMuted: Color(0x1FDC4444),
    warning: Color(0xFFD4940D),
    warningMuted: Color(0x1FD4940D),
    // Utility
    divider: Color(0x141A1A1A), // 8%
    shadow: Color(0x1A000000), // 10%
    overlay: Color(0x80000000), // 50%
  );

  /// Get the color scheme for the current theme
  static LedgerifyColorScheme of(BuildContext context) {
    final extension = Theme.of(context).extension<LedgerifyColorScheme>();
    if (extension != null) return extension;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ============================================
  // LEGACY STATIC COLORS (for backwards compatibility)
  // These reference the dark theme colors
  // ============================================

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF252525);
  static const Color surfaceHighlight = Color(0xFF2C2C2C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x80FFFFFF);
  static const Color textDisabled = Color(0x4DFFFFFF);
  static const Color accent = Color(0xFFA8E6CF);
  static const Color accentMuted = Color(0x26A8E6CF);
  static const Color accentPressed = Color(0xFF8BD4B8);
  static const Color negative = Color(0xFFFF6B6B);
  static const Color negativeMuted = Color(0x26FF6B6B);
  static const Color warning = Color(0xFFFFB347);
  static const Color warningMuted = Color(0x26FFB347);
  static const Color divider = Color(0x1AFFFFFF);
  static const Color shadow = Color(0x4D000000);
  static const Color overlay = Color(0x80000000);
}

/// Color scheme data class for Ledgerify themes
class LedgerifyColorScheme extends ThemeExtension<LedgerifyColorScheme> {
  final Brightness brightness;
  // Base
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHighlight;
  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  // Semantic
  final Color accent;
  final Color accentMuted;
  final Color accentPressed;
  final Color negative;
  final Color negativeMuted;
  final Color warning;
  final Color warningMuted;
  // Utility
  final Color divider;
  final Color shadow;
  final Color overlay;

  const LedgerifyColorScheme({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentMuted,
    required this.accentPressed,
    required this.negative,
    required this.negativeMuted,
    required this.warning,
    required this.warningMuted,
    required this.divider,
    required this.shadow,
    required this.overlay,
  });

  /// Returns the appropriate text color for an amount
  Color amountColor(double amount) {
    if (amount > 0) return accent;
    if (amount < 0) return negative;
    return textSecondary;
  }

  /// Map a Material 3 [ColorScheme] (e.g., Material You dynamic colors)
  /// into Ledgerify design tokens.
  static LedgerifyColorScheme fromMaterialColorScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    final background = scheme.surface;
    final surface = scheme.surface;
    final surfaceElevated = scheme.surfaceContainerHighest;
    final surfaceHighlight = scheme.surfaceContainerHigh;

    final textPrimary = scheme.onSurface;
    final textSecondary =
        (scheme.onSurfaceVariant).withValues(alpha: isDark ? 0.78 : 0.72);
    final textTertiary = scheme.onSurfaceVariant.withValues(alpha: 0.6);
    final textDisabled = scheme.onSurface.withValues(alpha: 0.38);

    final accent = scheme.primary;
    final accentMuted = scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12);
    final accentPressed =
        (isDark ? scheme.primaryContainer : scheme.primaryContainer);

    final negative = scheme.error;
    final negativeMuted = scheme.error.withValues(alpha: isDark ? 0.18 : 0.12);

    final warning = scheme.tertiary;
    final warningMuted =
        scheme.tertiary.withValues(alpha: isDark ? 0.18 : 0.12);

    final divider =
        scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6);
    final shadow = scheme.shadow;
    final overlay = scheme.scrim.withValues(alpha: 0.5);

    return LedgerifyColorScheme(
      brightness: scheme.brightness,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      surfaceHighlight: surfaceHighlight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      textDisabled: textDisabled,
      accent: accent,
      accentMuted: accentMuted,
      accentPressed: accentPressed,
      negative: negative,
      negativeMuted: negativeMuted,
      warning: warning,
      warningMuted: warningMuted,
      divider: divider,
      shadow: shadow,
      overlay: overlay,
    );
  }

  // ============================================
  // Pre-computed alpha variants
  // ============================================
  // These are cached getters to avoid creating new Color objects on every build

  /// Accent color with 20% alpha - use for faded backgrounds
  Color get accentFaded => accent.withValues(alpha: 0.2);

  /// Negative color with 20% alpha - use for faded negative backgrounds
  Color get negativeFaded => negative.withValues(alpha: 0.2);

  @override
  LedgerifyColorScheme copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? accent,
    Color? accentMuted,
    Color? accentPressed,
    Color? negative,
    Color? negativeMuted,
    Color? warning,
    Color? warningMuted,
    Color? divider,
    Color? shadow,
    Color? overlay,
  }) {
    return LedgerifyColorScheme(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      accentPressed: accentPressed ?? this.accentPressed,
      negative: negative ?? this.negative,
      negativeMuted: negativeMuted ?? this.negativeMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  LedgerifyColorScheme lerp(
    ThemeExtension<LedgerifyColorScheme>? other,
    double t,
  ) {
    if (other is! LedgerifyColorScheme) return this;
    return LedgerifyColorScheme(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHighlight: Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeMuted: Color.lerp(negativeMuted, other.negativeMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
