import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Ledgerify Theme
///
/// Complete Material 3 theme configuration implementing
/// the Ledgerify Design Language for both dark and light modes.
///
/// Philosophy: Quiet Finance — calm, premium, trustworthy
class LedgerifyTheme {
  LedgerifyTheme._();

  /// Dark theme for Ledgerify
  static ThemeData get darkTheme => _buildTheme(LedgerifyColors.dark);

  /// Light theme for Ledgerify
  static ThemeData get lightTheme => _buildTheme(LedgerifyColors.light);

  static ThemeData buildTheme({
    required LedgerifyColorScheme tokens,
    ColorScheme? materialColorScheme,
  }) {
    return _buildTheme(tokens, materialColorScheme: materialColorScheme);
  }

  /// Build theme from color scheme
  static ThemeData _buildTheme(
    LedgerifyColorScheme colors, {
    ColorScheme? materialColorScheme,
  }) {
    final isDark = colors.brightness == Brightness.dark;

    final colorScheme = materialColorScheme != null
        ? materialColorScheme.copyWith(
            // Keep Ledgerify finance semantics stable even with Material You.
            primary: colors.accent,
            onPrimary: isDark ? colors.background : Colors.white,
            secondary: colors.accent,
            onSecondary: isDark ? colors.background : Colors.white,
            error: colors.negative,
            onError: Colors.white,
          )
        : ColorScheme(
            brightness: colors.brightness,
            primary: colors.accent,
            onPrimary: isDark ? colors.background : Colors.white,
            secondary: colors.accent,
            onSecondary: isDark ? colors.background : Colors.white,
            surface: colors.surface,
            onSurface: colors.textPrimary,
            error: colors.negative,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      extensions: <ThemeExtension<dynamic>>[colors],

      // ========================================
      // COLOR SCHEME
      // ========================================
      colorScheme: colorScheme,

      // ========================================
      // SCAFFOLD
      // ========================================
      scaffoldBackgroundColor: colors.background,

      // ========================================
      // APP BAR
      // ========================================
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LedgerifyTypography.headlineMedium.copyWith(
          color: colors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),

      // ========================================
      // CARD
      // ========================================
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: LedgerifyElevation.none,
        shadowColor: colors.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // ========================================
      // ELEVATED BUTTON (Primary CTA)
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: isDark ? colors.background : Colors.white,
          disabledBackgroundColor: colors.surfaceHighlight,
          disabledForegroundColor: colors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
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
          backgroundColor: colors.accent,
          foregroundColor: isDark ? colors.background : Colors.white,
          disabledBackgroundColor: colors.surfaceHighlight,
          disabledForegroundColor: colors.textDisabled,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
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
          foregroundColor: colors.accent,
          disabledForegroundColor: colors.textDisabled,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          side: BorderSide(
            color: colors.accent.withValues(alpha: 0.5),
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
          foregroundColor: colors.accent,
          disabledForegroundColor: colors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(
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
          foregroundColor: colors.textSecondary,
          disabledForegroundColor: colors.textDisabled,
          minimumSize: const Size(48, 48),
        ),
      ),

      // ========================================
      // FLOATING ACTION BUTTON
      // ========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: isDark ? colors.background : Colors.white,
        elevation: LedgerifyElevation.medium,
        focusElevation: LedgerifyElevation.medium,
        hoverElevation: LedgerifyElevation.high,
        highlightElevation: LedgerifyElevation.high,
        shape: const RoundedRectangleBorder(
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
        fillColor: colors.surfaceHighlight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide(
            color: colors.accent,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide(
            color: colors.negative,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
          borderSide: BorderSide(
            color: colors.negative,
            width: 1,
          ),
        ),
        hintStyle: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textTertiary,
        ),
        labelStyle: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textSecondary,
        ),
        errorStyle: LedgerifyTypography.bodySmall.copyWith(
          color: colors.negative,
        ),
      ),

      // ========================================
      // DROPDOWN
      // ========================================
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.surfaceHighlight,
          border: const OutlineInputBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(colors.surfaceElevated),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
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
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        titleTextStyle: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
        subtitleTextStyle: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
        leadingAndTrailingTextStyle: LedgerifyTypography.amountMedium.copyWith(
          color: colors.textPrimary,
        ),
      ),

      // ========================================
      // DIVIDER
      // ========================================
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 0,
      ),

      // ========================================
      // BOTTOM NAVIGATION BAR
      // ========================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // ========================================
      // NAVIGATION BAR (Material 3)
      // ========================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentMuted,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colors.accent,
              size: 24,
            );
          }
          return IconThemeData(
            color: colors.textTertiary,
            size: 24,
          );
        }),
      ),

      // ========================================
      // BOTTOM SHEET
      // ========================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        elevation: LedgerifyElevation.high,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusTopXl,
        ),
        showDragHandle: true,
        dragHandleColor: colors.textTertiary,
        dragHandleSize: const Size(32, 4),
      ),

      // ========================================
      // DIALOG
      // ========================================
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        elevation: LedgerifyElevation.high,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
        titleTextStyle: LedgerifyTypography.headlineMedium.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),

      // ========================================
      // SNACKBAR
      // ========================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: LedgerifyElevation.medium,
      ),

      // ========================================
      // CHIP
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceHighlight,
        selectedColor: colors.accentMuted,
        disabledColor: colors.surface,
        labelStyle: LedgerifyTypography.labelMedium.copyWith(
          color: colors.textPrimary,
        ),
        secondaryLabelStyle: LedgerifyTypography.labelSmall.copyWith(
          color: colors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusFull,
        ),
        side: BorderSide.none,
      ),

      // ========================================
      // PROGRESS INDICATOR
      // ========================================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceHighlight,
        circularTrackColor: colors.surfaceHighlight,
      ),

      // ========================================
      // SLIDER
      // ========================================
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: colors.surfaceHighlight,
        thumbColor: colors.accent,
        overlayColor: colors.accentMuted,
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
            return colors.accent;
          }
          return colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentMuted;
          }
          return colors.surfaceHighlight;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ========================================
      // RADIO
      // ========================================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.textTertiary;
        }),
      ),

      // ========================================
      // DATE PICKER
      // ========================================
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surfaceElevated,
        headerBackgroundColor: colors.surface,
        headerForegroundColor: colors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? colors.background : Colors.white;
          }
          return colors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(colors.accent),
        todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        todayBorder: BorderSide(color: colors.accent, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
      ),

      // ========================================
      // TEXT SELECTION
      // ========================================
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accentMuted,
        selectionHandleColor: colors.accent,
      ),

      // ========================================
      // TYPOGRAPHY
      // ========================================
      textTheme: TextTheme(
        displayLarge: LedgerifyTypography.displayLarge
            .copyWith(color: colors.textPrimary),
        displayMedium: LedgerifyTypography.displayMedium
            .copyWith(color: colors.textPrimary),
        displaySmall: LedgerifyTypography.displaySmall
            .copyWith(color: colors.textPrimary),
        headlineLarge: LedgerifyTypography.headlineLarge
            .copyWith(color: colors.textPrimary),
        headlineMedium: LedgerifyTypography.headlineMedium
            .copyWith(color: colors.textPrimary),
        headlineSmall: LedgerifyTypography.headlineSmall
            .copyWith(color: colors.textPrimary),
        bodyLarge:
            LedgerifyTypography.bodyLarge.copyWith(color: colors.textPrimary),
        bodyMedium: LedgerifyTypography.bodyMedium
            .copyWith(color: colors.textSecondary),
        bodySmall:
            LedgerifyTypography.bodySmall.copyWith(color: colors.textTertiary),
        labelLarge:
            LedgerifyTypography.labelLarge.copyWith(color: colors.textPrimary),
        labelMedium: LedgerifyTypography.labelMedium
            .copyWith(color: colors.textSecondary),
        labelSmall:
            LedgerifyTypography.labelSmall.copyWith(color: colors.textTertiary),
      ),
    );
  }
}
