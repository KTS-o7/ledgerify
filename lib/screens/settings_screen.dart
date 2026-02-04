import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/custom_category_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
import '../services/tag_service.dart';
import '../services/theme_service.dart';
import '../theme/ledgerify_theme.dart';
import 'category_management_screen.dart';
import 'notification_settings_screen.dart';
import 'sms_import_screen.dart';
import 'tag_management_screen.dart';

/// Settings Screen - Ledgerify Design Language
///
/// Allows users to configure app preferences including theme and notifications.
/// Note: Recurring expenses and income are now accessed via bottom navigation tab.
class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final NotificationService notificationService;
  final NotificationPreferencesService notificationPrefsService;
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;

  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.tagService,
    required this.customCategoryService,
    required this.notificationService,
    required this.notificationPrefsService,
    required this.smsPermissionService,
    required this.smsTransactionService,
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
        automaticallyImplyLeading: false, // No back button when in tab
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
          LedgerifySpacing.verticalSm,
          _SettingsCard(
            colors: colors,
            child: Column(
              children: [
                _ThemeTile(
                  themeService: themeService,
                  colors: colors,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _DynamicColorTile(
                  themeService: themeService,
                  colors: colors,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _NotificationsTile(
                  colors: colors,
                  notificationService: notificationService,
                  notificationPrefsService: notificationPrefsService,
                ),
              ],
            ),
          ),

          LedgerifySpacing.verticalXl,

          // Data section
          _SectionHeader(title: 'Data', colors: colors),
          LedgerifySpacing.verticalSm,
          _SettingsCard(
            colors: colors,
            child: Column(
              children: [
                _CustomCategoriesTile(
                  colors: colors,
                  customCategoryService: customCategoryService,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _TagsTile(
                  colors: colors,
                  tagService: tagService,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _SmsImportTile(
                  colors: colors,
                  smsPermissionService: smsPermissionService,
                  smsTransactionService: smsTransactionService,
                  customCategoryService: customCategoryService,
                ),
              ],
            ),
          ),

          LedgerifySpacing.verticalXl,

          // About section
          _SectionHeader(title: 'About', colors: colors),
          LedgerifySpacing.verticalSm,
          _SettingsCard(
            colors: colors,
            child: Column(
              children: [
                _AboutTile(colors: colors),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _GitHubTile(colors: colors),
              ],
            ),
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
              LedgerifySpacing.horizontalSm,
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
            LedgerifySpacing.verticalLg,

            // Title
            Text(
              'Theme',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalLg,

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

            LedgerifySpacing.verticalSm,
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
            LedgerifySpacing.horizontalMd,

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

/// Material You / dynamic color toggle
class _DynamicColorTile extends StatelessWidget {
  final ThemeService themeService;
  final LedgerifyColorScheme colors;

  const _DynamicColorTile({
    required this.themeService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeService.useDynamicColor,
      builder: (context, enabled, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: Icon(
            Icons.palette_rounded,
            color: colors.textSecondary,
          ),
          title: Text(
            'Material You colors',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Android 12+',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
          trailing: Switch(
            value: enabled,
            onChanged: themeService.setUseDynamicColor,
            activeColor: colors.accent,
          ),
          onTap: () => themeService.setUseDynamicColor(!enabled),
        );
      },
    );
  }
}

/// Custom Categories tile
class _CustomCategoriesTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final CustomCategoryService customCategoryService;

  const _CustomCategoriesTile({
    required this.colors,
    required this.customCategoryService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.category_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Custom Categories',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryManagementScreen(
              categoryService: customCategoryService,
            ),
          ),
        );
      },
    );
  }
}

/// Tags tile
class _TagsTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final TagService tagService;

  const _TagsTile({
    required this.colors,
    required this.tagService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.label_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Tags',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagManagementScreen(
              tagService: tagService,
            ),
          ),
        );
      },
    );
  }
}

/// SMS Import tile
class _SmsImportTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
  final CustomCategoryService customCategoryService;

  const _SmsImportTile({
    required this.colors,
    required this.smsPermissionService,
    required this.smsTransactionService,
    required this.customCategoryService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.sms_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'SMS Import',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Import transactions from bank SMS',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmsImportScreen(
              smsPermissionService: smsPermissionService,
              smsTransactionService: smsTransactionService,
              customCategoryService: customCategoryService,
            ),
          ),
        );
      },
    );
  }
}

/// Notifications tile
class _NotificationsTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final NotificationService notificationService;
  final NotificationPreferencesService notificationPrefsService;

  const _NotificationsTile({
    required this.colors,
    required this.notificationService,
    required this.notificationPrefsService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.notifications_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Notifications',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationSettingsScreen(
              preferencesService: notificationPrefsService,
              notificationService: notificationService,
            ),
          ),
        );
      },
    );
  }
}

/// About tile with version info
class _AboutTile extends StatefulWidget {
  final LedgerifyColorScheme colors;

  const _AboutTile({required this.colors});

  @override
  State<_AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<_AboutTile> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

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
          color: widget.colors.textPrimary,
        ),
      ),
      trailing: Text(
        _version,
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: widget.colors.textTertiary,
        ),
      ),
    );
  }
}

/// GitHub repository link tile
class _GitHubTile extends StatelessWidget {
  final LedgerifyColorScheme colors;

  const _GitHubTile({required this.colors});

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/KTS-o7/ledgerify');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.code_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Source Code',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'github.com/KTS-o7/ledgerify',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        color: colors.textTertiary,
        size: 20,
      ),
      onTap: _openGitHub,
    );
  }
}
