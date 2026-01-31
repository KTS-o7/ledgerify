import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Ledgerify Theme
///
/// Complete Material 3 theme configuration implementing
/// the Ledgerify Design Language.
///
/// Philosophy: Quiet Finance — calm, premium, trustworthy
class LedgerifyTheme {
  LedgerifyTheme._();

  /// The main dark theme for Ledgerify
  /// This is the primary (and only) theme - no light mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ========================================
      // COLOR SCHEME
      // ========================================
      colorScheme: const ColorScheme.dark(
        primary: LedgerifyColors.accent,
        onPrimary: LedgerifyColors.background,
        secondary: LedgerifyColors.accent,
        onSecondary: LedgerifyColors.background,
        surface: LedgerifyColors.surface,
        onSurface: LedgerifyColors.textPrimary,
        error: LedgerifyColors.negative,
        onError: LedgerifyColors.textPrimary,
      ),

      // ========================================
      // SCAFFOLD
      // ========================================
      scaffoldBackgroundColor: LedgerifyColors.background,

      // ========================================
      // APP BAR
      // ========================================
      appBarTheme: const AppBarTheme(
        backgroundColor: LedgerifyColors.background,
        foregroundColor: LedgerifyColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LedgerifyTypography.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ========================================
      // CARD
      // ========================================
      cardTheme: CardThemeData(
        color: LedgerifyColors.surface,
        elevation: LedgerifyElevation.none,
        shadowColor: LedgerifyColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // ========================================
      // ELEVATED BUTTON (Primary CTA)
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LedgerifyColors.accent,
          foregroundColor: LedgerifyColors.background,
          disabledBackgroundColor: LedgerifyColors.surfaceHighlight,
          disabledForegroundColor: LedgerifyColors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          textStyle: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================
      // FILLED BUTTON (Alternative Primary)
      // ========================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LedgerifyColors.accent,
          foregroundColor: LedgerifyColors.background,
          disabledBackgroundColor: LedgerifyColors.surfaceHighlight,
          disabledForegroundColor: LedgerifyColors.textDisabled,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          textStyle: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================
      // OUTLINED BUTTON (Secondary)
      // ========================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LedgerifyColors.accent,
          disabledForegroundColor: LedgerifyColors.textDisabled,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          side: BorderSide(
            color: LedgerifyColors.accent.withOpacity(0.5),
            width: 1,
          ),
          textStyle: LedgerifyTypography.labelLarge,
        ),
      ),

      // ========================================
      // TEXT BUTTON (Tertiary)
      // ========================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LedgerifyColors.accent,
          disabledForegroundColor: LedgerifyColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusSm,
          ),
          textStyle: LedgerifyTypography.labelLarge,
        ),
      ),

      // ========================================
      // ICON BUTTON
      // ========================================
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: LedgerifyColors.textSecondary,
          disabledForegroundColor: LedgerifyColors.textDisabled,
          minimumSize: const Size(48, 48),
        ),
      ),

      // ========================================
      // FLOATING ACTION BUTTON
      // ========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: LedgerifyColors.accent,
        foregroundColor: LedgerifyColors.background,
        elevation: LedgerifyElevation.medium,
        focusElevation: LedgerifyElevation.medium,
        hoverElevation: LedgerifyElevation.high,
        highlightElevation: LedgerifyElevation.high,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        extendedTextStyle: LedgerifyTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // ========================================
      // INPUT DECORATION (Text Fields)
      // ========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LedgerifyColors.surfaceHighlight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: const BorderSide(
            color: LedgerifyColors.accent,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: const BorderSide(
            color: LedgerifyColors.negative,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: const BorderSide(
            color: LedgerifyColors.negative,
            width: 1,
          ),
        ),
        hintStyle: LedgerifyTypography.bodyLarge.copyWith(
          color: LedgerifyColors.textTertiary,
        ),
        labelStyle: LedgerifyTypography.bodySmall.copyWith(
          color: LedgerifyColors.textSecondary,
        ),
        errorStyle: LedgerifyTypography.bodySmall.copyWith(
          color: LedgerifyColors.negative,
        ),
      ),

      // ========================================
      // DROPDOWN
      // ========================================
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: LedgerifyColors.surfaceHighlight,
          border: OutlineInputBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStateProperty.all(LedgerifyColors.surfaceElevated),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
          ),
          elevation: WidgetStateProperty.all(LedgerifyElevation.medium),
        ),
      ),

      // ========================================
      // LIST TILE
      // ========================================
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: LedgerifySpacing.listItemPadding,
        minVerticalPadding: LedgerifySpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        titleTextStyle: LedgerifyTypography.bodyLarge,
        subtitleTextStyle: LedgerifyTypography.bodySmall,
        leadingAndTrailingTextStyle: LedgerifyTypography.amountMedium,
      ),

      // ========================================
      // DIVIDER
      // ========================================
      dividerTheme: const DividerThemeData(
        color: LedgerifyColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ========================================
      // BOTTOM NAVIGATION BAR
      // ========================================
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LedgerifyColors.surface,
        selectedItemColor: LedgerifyColors.accent,
        unselectedItemColor: LedgerifyColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // ========================================
      // NAVIGATION BAR (Material 3)
      // ========================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LedgerifyColors.surface,
        indicatorColor: LedgerifyColors.accentMuted,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: LedgerifyColors.accent,
              size: 24,
            );
          }
          return const IconThemeData(
            color: LedgerifyColors.textTertiary,
            size: 24,
          );
        }),
      ),

      // ========================================
      // BOTTOM SHEET
      // ========================================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LedgerifyColors.surfaceElevated,
        modalBackgroundColor: LedgerifyColors.surfaceElevated,
        elevation: LedgerifyElevation.high,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusTopXl,
        ),
        showDragHandle: true,
        dragHandleColor: LedgerifyColors.textTertiary,
        dragHandleSize: Size(32, 4),
      ),

      // ========================================
      // DIALOG
      // ========================================
      dialogTheme: DialogThemeData(
        backgroundColor: LedgerifyColors.surfaceElevated,
        elevation: LedgerifyElevation.high,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
        titleTextStyle: LedgerifyTypography.headlineMedium,
        contentTextStyle: LedgerifyTypography.bodyMedium,
      ),

      // ========================================
      // SNACKBAR
      // ========================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LedgerifyColors.surfaceElevated,
        contentTextStyle: LedgerifyTypography.bodyMedium.copyWith(
          color: LedgerifyColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: LedgerifyElevation.medium,
      ),

      // ========================================
      // CHIP
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: LedgerifyColors.surfaceHighlight,
        selectedColor: LedgerifyColors.accentMuted,
        disabledColor: LedgerifyColors.surface,
        labelStyle: LedgerifyTypography.labelMedium,
        secondaryLabelStyle: LedgerifyTypography.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusFull,
        ),
        side: BorderSide.none,
      ),

      // ========================================
      // PROGRESS INDICATOR
      // ========================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LedgerifyColors.accent,
        linearTrackColor: LedgerifyColors.surfaceHighlight,
        circularTrackColor: LedgerifyColors.surfaceHighlight,
      ),

      // ========================================
      // SLIDER
      // ========================================
      sliderTheme: SliderThemeData(
        activeTrackColor: LedgerifyColors.accent,
        inactiveTrackColor: LedgerifyColors.surfaceHighlight,
        thumbColor: LedgerifyColors.accent,
        overlayColor: LedgerifyColors.accentMuted,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),

      // ========================================
      // SWITCH
      // ========================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LedgerifyColors.accent;
          }
          return LedgerifyColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LedgerifyColors.accentMuted;
          }
          return LedgerifyColors.surfaceHighlight;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ========================================
      // DATE PICKER
      // ========================================
      datePickerTheme: DatePickerThemeData(
        backgroundColor: LedgerifyColors.surfaceElevated,
        headerBackgroundColor: LedgerifyColors.surface,
        headerForegroundColor: LedgerifyColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LedgerifyColors.background;
          }
          return LedgerifyColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LedgerifyColors.accent;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(LedgerifyColors.accent),
        todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        todayBorder: const BorderSide(color: LedgerifyColors.accent, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
      ),

      // ========================================
      // TEXT SELECTION
      // ========================================
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: LedgerifyColors.accent,
        selectionColor: LedgerifyColors.accentMuted,
        selectionHandleColor: LedgerifyColors.accent,
      ),

      // ========================================
      // TYPOGRAPHY
      // ========================================
      textTheme: const TextTheme(
        displayLarge: LedgerifyTypography.displayLarge,
        displayMedium: LedgerifyTypography.displayMedium,
        displaySmall: LedgerifyTypography.displaySmall,
        headlineLarge: LedgerifyTypography.headlineLarge,
        headlineMedium: LedgerifyTypography.headlineMedium,
        headlineSmall: LedgerifyTypography.headlineSmall,
        bodyLarge: LedgerifyTypography.bodyLarge,
        bodyMedium: LedgerifyTypography.bodyMedium,
        bodySmall: LedgerifyTypography.bodySmall,
        labelLarge: LedgerifyTypography.labelLarge,
        labelMedium: LedgerifyTypography.labelMedium,
        labelSmall: LedgerifyTypography.labelSmall,
      ),
    );
  }
}
