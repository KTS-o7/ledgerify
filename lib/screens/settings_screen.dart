import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/ledgerify_theme.dart';

/// Settings Screen - Ledgerify Design Language
///
/// Allows users to configure app preferences including theme.
class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;

  const SettingsScreen({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: colors.textPrimary,
        ),
        title: Text(
          'Settings',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        children: [
          // Appearance section
          _SectionHeader(title: 'Appearance', colors: colors),
          SizedBox(height: LedgerifySpacing.sm),
          _SettingsCard(
            colors: colors,
            child: _ThemeTile(
              themeService: themeService,
              colors: colors,
            ),
          ),

          SizedBox(height: LedgerifySpacing.xl),

          // About section
          _SectionHeader(title: 'About', colors: colors),
          SizedBox(height: LedgerifySpacing.sm),
          _SettingsCard(
            colors: colors,
            child: _AboutTile(colors: colors),
          ),
        ],
      ),
    );
  }
}

/// Section header text
class _SectionHeader extends StatelessWidget {
  final String title;
  final LedgerifyColorScheme colors;

  const _SectionHeader({
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: LedgerifySpacing.xs),
      child: Text(
        title,
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.textTertiary,
        ),
      ),
    );
  }
}

/// Card container for settings items
class _SettingsCard extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final Widget child;

  const _SettingsCard({
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: child,
    );
  }
}

/// Theme selection tile
class _ThemeTile extends StatelessWidget {
  final ThemeService themeService;
  final LedgerifyColorScheme colors;

  const _ThemeTile({
    required this.themeService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeService.themeMode,
      builder: (context, currentMode, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          title: Text(
            'Theme',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentMode.displayName,
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              SizedBox(width: LedgerifySpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
              ),
            ],
          ),
          onTap: () => _showThemeBottomSheet(context, currentMode),
        );
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context, AppThemeMode currentMode) {
    final colors = LedgerifyColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => _ThemeBottomSheet(
        themeService: themeService,
        currentMode: currentMode,
        colors: colors,
      ),
    );
  }
}

/// Theme selection bottom sheet
class _ThemeBottomSheet extends StatelessWidget {
  final ThemeService themeService;
  final AppThemeMode currentMode;
  final LedgerifyColorScheme colors;

  const _ThemeBottomSheet({
    required this.themeService,
    required this.currentMode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: LedgerifySpacing.lg),

            // Title
            Text(
              'Theme',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: LedgerifySpacing.lg),

            // Options
            ...AppThemeMode.values.map((mode) => _ThemeOption(
                  mode: mode,
                  isSelected: mode == currentMode,
                  colors: colors,
                  onTap: () {
                    themeService.setThemeMode(mode);
                    Navigator.pop(context);
                  },
                )),

            SizedBox(height: LedgerifySpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Single theme option in bottom sheet
class _ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final LedgerifyColorScheme colors;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: LedgerifyRadius.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: LedgerifySpacing.md,
          horizontal: LedgerifySpacing.sm,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.accent : colors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: LedgerifySpacing.md),

            // Label
            Text(
              mode.displayName,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// About tile with version info
class _AboutTile extends StatelessWidget {
  final LedgerifyColorScheme colors;

  const _AboutTile({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      title: Text(
        'Version',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      trailing: Text(
        '1.0.0',
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textTertiary,
        ),
      ),
    );
  }
}
