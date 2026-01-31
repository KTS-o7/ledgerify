import 'package:flutter/material.dart';

/// Ledgerify Spacing System
///
/// Base unit: 4dp
/// All spacing should be multiples of 4dp for consistency.
///
/// Philosophy: Generous spacing, let content breathe
class LedgerifySpacing {
  LedgerifySpacing._();

  // ============================================
  // SPACING VALUES
  // ============================================

  /// 4dp - Tight gaps, icon padding
  static const double xs = 4;

  /// 8dp - Related element gaps
  static const double sm = 8;

  /// 12dp - Intra-card spacing
  static const double md = 12;

  /// 16dp - Card padding, section gaps
  static const double lg = 16;

  /// 24dp - Between cards
  static const double xl = 24;

  /// 32dp - Section separators
  static const double xxl = 32;

  /// 48dp - Major section breaks
  static const double xxxl = 48;

  // ============================================
  // SCREEN MARGINS
  // ============================================

  /// Standard horizontal padding for screens
  static const double screenHorizontal = 16;

  /// Standard vertical padding for screen content
  static const double screenVertical = 16;

  /// Padding for screen edges
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Horizontal only padding
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  // ============================================
  // CARD PADDING
  // ============================================

  /// Standard card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Compact card padding
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);

  /// Large card padding for hero content
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);

  // ============================================
  // LIST ITEM PADDING
  // ============================================

  /// Standard list item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Compact list item padding
  static const EdgeInsets listItemPaddingCompact = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  // ============================================
  // GAP HELPERS
  // ============================================

  /// Vertical gap widgets for common spacing
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);
  static const SizedBox verticalXxxl = SizedBox(height: xxxl);

  /// Horizontal gap widgets for common spacing
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
}

/// Ledgerify Border Radius System
///
/// Consistent rounded corners throughout the app.
/// Cards are rounded everywhere.
class LedgerifyRadius {
  LedgerifyRadius._();

  // ============================================
  // RADIUS VALUES
  // ============================================

  /// 8dp - Small chips, badges
  static const double sm = 8;

  /// 12dp - Buttons, input fields
  static const double md = 12;

  /// 16dp - Cards, containers
  static const double lg = 16;

  /// 24dp - Large cards, bottom sheets
  static const double xl = 24;

  /// Full circle/pill
  static const double full = 9999;

  // ============================================
  // BORDER RADIUS HELPERS
  // ============================================

  /// Small border radius
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(sm));

  /// Medium border radius (buttons, inputs)
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(md));

  /// Large border radius (cards)
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(lg));

  /// Extra large border radius (bottom sheets)
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(xl));

  /// Pill/full radius
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(full));

  /// Top only radius for bottom sheets
  static const BorderRadius borderRadiusTopXl = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}

/// Ledgerify Elevation System
///
/// Soft elevation and depth instead of visible borders.
/// Surfaces float at different levels.
class LedgerifyElevation {
  LedgerifyElevation._();

  // ============================================
  // ELEVATION VALUES
  // ============================================

  /// No elevation - background level
  static const double none = 0;

  /// Level 1 - Cards, containers
  static const double low = 2;

  /// Level 2 - Elevated cards, dialogs
  static const double medium = 4;

  /// Level 3 - Modals, bottom sheets
  static const double high = 8;

  // ============================================
  // BOX SHADOWS
  // ============================================

  /// Shadow for level 1 elevation
  static const List<BoxShadow> shadowLow = [
    BoxShadow(
      color: Color(0x4D000000), // 30% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Shadow for level 2 elevation
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x66000000), // 40% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Shadow for level 3 elevation
  static const List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: Color(0x80000000), // 50% black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
