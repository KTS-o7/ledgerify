import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/expense.dart';
import '../models/widget_config.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
import '../services/tag_service.dart';
import '../services/theme_service.dart';
import '../services/transaction_csv_codec.dart';
import '../services/transaction_csv_service.dart';
import '../services/widget_service.dart';
import '../theme/ledgerify_theme.dart';
import 'category_management_screen.dart';
import 'csv_import_preview_screen.dart';
import 'nerd_stats_screen.dart';
import 'notification_settings_screen.dart';
import 'sms_import_screen.dart';
import 'tag_management_screen.dart';

/// Settings Screen - Ledgerify Design Language
///
/// Allows users to configure app preferences including theme and notifications.
/// Note: Recurring expenses and income are now accessed via bottom navigation tab.
class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;
  final ExpenseService expenseService;
  final IncomeService incomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final NotificationService notificationService;
  final NotificationPreferencesService notificationPrefsService;
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
  final WidgetService? widgetService;

  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.expenseService,
    required this.incomeService,
    required this.tagService,
    required this.customCategoryService,
    required this.notificationService,
    required this.notificationPrefsService,
    required this.smsPermissionService,
    required this.smsTransactionService,
    this.widgetService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);
    final csvService = TransactionCsvService(
      expenseService: expenseService,
      incomeService: incomeService,
      tagService: tagService,
      customCategoryService: customCategoryService,
    );

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

          // Widget section (only show if widgetService is available)
          if (widgetService != null) ...[
            LedgerifySpacing.verticalXl,
            _SectionHeader(title: 'Home Widget', colors: colors),
            LedgerifySpacing.verticalSm,
            _SettingsCard(
              colors: colors,
              child: Column(
                children: [
                  _WidgetUpdateFrequencyTile(
                    widgetService: widgetService!,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colors.surfaceHighlight,
                  ),
                  _WidgetShowBudgetTile(
                    widgetService: widgetService!,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colors.surfaceHighlight,
                  ),
                  _WidgetShowAlertsTile(
                    widgetService: widgetService!,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colors.surfaceHighlight,
                  ),
                  _WidgetQuickAddCategoriesTile(
                    widgetService: widgetService!,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colors.surfaceHighlight,
                  ),
                  _WidgetSyncNowTile(
                    widgetService: widgetService!,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],

          LedgerifySpacing.verticalXl,

          // Data section
          _SectionHeader(title: 'Data', colors: colors),
          LedgerifySpacing.verticalSm,
          _SettingsCard(
            colors: colors,
            child: Column(
              children: [
                _ExportCsvTile(
                  colors: colors,
                  csvService: csvService,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _ImportCsvTile(
                  colors: colors,
                  csvService: csvService,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
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
                _NerdStatsTile(
                  colors: colors,
                  themeService: themeService,
                  expenseService: expenseService,
                  incomeService: incomeService,
                  tagService: tagService,
                  customCategoryService: customCategoryService,
                  smsTransactionService: smsTransactionService,
                ),
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
            activeThumbColor: colors.accent,
          ),
          onTap: () => themeService.setUseDynamicColor(!enabled),
        );
      },
    );
  }
}

/// CSV export tile
class _ExportCsvTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final TransactionCsvService csvService;

  const _ExportCsvTile({
    required this.colors,
    required this.csvService,
  });

  Future<T?> _runWithLoadingDialog<T>(
    BuildContext context, {
    required String message,
    required Future<T> Function() action,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
            ),
            LedgerifySpacing.horizontalMd,
            Expanded(
              child: Text(
                message,
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await action();
      if (context.mounted) Navigator.pop(context);
      return result;
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      rethrow;
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _export(BuildContext context) async {
    try {
      final range = await _pickExportRange(context);
      if (range == null || !context.mounted) return;

      final csv = await _runWithLoadingDialog<String>(
        context,
        message: 'Preparing CSV…',
        action: () => csvService.exportCsv(
          start: range.start,
          end: range.end,
        ),
      );
      if (csv == null || !context.mounted) return;

      final fileName = range.isAllTime
          ? _buildAllTimeFileName()
          : _buildRangeFileName(range.start!, range.end!);

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csv, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          fileNameOverrides: [fileName],
          subject: 'Ledgerify transactions CSV',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export failed',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.surface,
        ),
      );
    }
  }

  Future<_ExportRange?> _pickExportRange(BuildContext context) async {
    final selected = await showModalBottomSheet<_ExportRange>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LedgerifyRadius.xl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.all_inbox_rounded,
                color: colors.textSecondary,
              ),
              title: Text(
                'All time',
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Export every transaction',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              onTap: () => Navigator.pop(context, _ExportRange.allTime()),
            ),
            ListTile(
              leading: Icon(
                Icons.date_range_rounded,
                color: colors.textSecondary,
              ),
              title: Text(
                'Date range',
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Export a specific period',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              onTap: () => Navigator.pop(context, _ExportRange.pickRange()),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return null;
    if (selected == null) return null;
    if (selected.isAllTime) return selected;
    if (!selected.needsPicker) return selected;

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
      helpText: 'Select export range',
    );
    if (!context.mounted) return null;
    if (picked == null) return null;
    return _ExportRange(start: picked.start, end: picked.end);
  }

  String _buildAllTimeFileName() {
    final now = DateTime.now();
    return 'ledgerify-transactions-${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}.csv';
  }

  String _buildRangeFileName(DateTime start, DateTime end) {
    final s = '${start.year}${_two(start.month)}${_two(start.day)}';
    final e = '${end.year}${_two(end.month)}${_two(end.day)}';
    return 'ledgerify-transactions-$s-$e.csv';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.upload_file_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Export CSV',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Share a CSV of transactions',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () => _export(context),
    );
  }
}

/// CSV import tile
class _ImportCsvTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final TransactionCsvService csvService;

  const _ImportCsvTile({
    required this.colors,
    required this.csvService,
  });

  Future<void> _import(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return;
      if (bytes.length > 10 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV file is too large (max 10MB)',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            backgroundColor: colors.surface,
          ),
        );
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final normalized =
          content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trimLeft();
      final hasHeader = normalized.startsWith(TransactionCsvCodec.commentLine);
      final rows = await compute(decodeTransactionCsvRows, content);
      final preview = csvService.previewImportRows(
        rows,
        hasFormatHeader: hasHeader,
      );

      if (!context.mounted) return;
      final importResult = await Navigator.push<CsvImportResult>(
        context,
        MaterialPageRoute(
          builder: (context) => CsvImportPreviewScreen(
            csvService: csvService,
            preview: preview,
            sourceLabel: file.name,
          ),
        ),
      );

      if (importResult == null || !context.mounted) return;

      final imported =
          importResult.importedExpenses + importResult.importedIncomes;
      final message = imported == 0
          ? 'No transactions imported'
          : 'Imported $imported (${importResult.importedExpenses} expenses, ${importResult.importedIncomes} income)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.surface,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import failed',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.surface,
        ),
      );
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
        Icons.download_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Import CSV',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Import transactions from a CSV',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () => _import(context),
    );
  }
}

class _ExportRange {
  final DateTime? start;
  final DateTime? end;
  final bool isAllTime;
  final bool needsPicker;

  const _ExportRange({
    required this.start,
    required this.end,
  })  : isAllTime = false,
        needsPicker = false;

  _ExportRange.allTime()
      : start = null,
        end = null,
        isAllTime = true,
        needsPicker = false;

  _ExportRange.pickRange()
      : start = null,
        end = null,
        isAllTime = false,
        needsPicker = true;
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

class _NerdStatsTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final ThemeService themeService;
  final ExpenseService expenseService;
  final IncomeService incomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final SmsTransactionService smsTransactionService;

  const _NerdStatsTile({
    required this.colors,
    required this.themeService,
    required this.expenseService,
    required this.incomeService,
    required this.tagService,
    required this.customCategoryService,
    required this.smsTransactionService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.insights_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'Stats for nerds',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Storage + internal counts',
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
            builder: (context) => NerdStatsScreen(
              themeService: themeService,
              expenseService: expenseService,
              incomeService: incomeService,
              tagService: tagService,
              customCategoryService: customCategoryService,
              smsTransactionService: smsTransactionService,
            ),
          ),
        );
      },
    );
  }
}

/// Widget update frequency selection tile
class _WidgetUpdateFrequencyTile extends StatelessWidget {
  final WidgetService widgetService;
  final LedgerifyColorScheme colors;

  const _WidgetUpdateFrequencyTile({
    required this.widgetService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widgetService.configBox.listenable(),
      builder: (context, box, _) {
        final config = widgetService.config;
        final currentFrequency = config.updateFrequency;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: Icon(
            Icons.update_rounded,
            color: colors.textSecondary,
          ),
          title: Text(
            'Update frequency',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentFrequency.displayName,
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
          onTap: () => _showFrequencyBottomSheet(context, currentFrequency),
        );
      },
    );
  }

  void _showFrequencyBottomSheet(
      BuildContext context, WidgetUpdateFrequency currentFrequency) {
    final colors = LedgerifyColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => SafeArea(
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
                'Update frequency',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              LedgerifySpacing.verticalSm,
              Text(
                'How often the widget refreshes data',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              LedgerifySpacing.verticalLg,

              // Options
              ...WidgetUpdateFrequency.values.map((frequency) => InkWell(
                    onTap: () {
                      widgetService.setUpdateFrequency(frequency);
                      Navigator.pop(context);
                    },
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
                                color: frequency == currentFrequency
                                    ? colors.accent
                                    : colors.textTertiary,
                                width: 2,
                              ),
                            ),
                            child: frequency == currentFrequency
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
                            frequency.displayName,
                            style: LedgerifyTypography.bodyLarge.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              LedgerifySpacing.verticalSm,
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget show budget progress toggle tile
class _WidgetShowBudgetTile extends StatelessWidget {
  final WidgetService widgetService;
  final LedgerifyColorScheme colors;

  const _WidgetShowBudgetTile({
    required this.widgetService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widgetService.configBox.listenable(),
      builder: (context, box, _) {
        final config = widgetService.config;
        final showBudget = config.showBudgetProgress;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: Icon(
            Icons.pie_chart_rounded,
            color: colors.textSecondary,
          ),
          title: Text(
            'Show budget progress',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Display spent vs budget on widget',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
          trailing: Switch(
            value: showBudget,
            onChanged: (value) {
              widgetService.updateConfig(
                config.copyWith(showBudgetProgress: value),
              );
            },
            activeThumbColor: colors.accent,
          ),
          onTap: () {
            widgetService.updateConfig(
              config.copyWith(showBudgetProgress: !showBudget),
            );
          },
        );
      },
    );
  }
}

/// Widget show alerts toggle tile
class _WidgetShowAlertsTile extends StatelessWidget {
  final WidgetService widgetService;
  final LedgerifyColorScheme colors;

  const _WidgetShowAlertsTile({
    required this.widgetService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widgetService.configBox.listenable(),
      builder: (context, box, _) {
        final config = widgetService.config;
        final showAlerts = config.showAlerts;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: Icon(
            Icons.info_rounded,
            color: colors.textSecondary,
          ),
          title: Text(
            'Show contextual alerts',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Time-based tips and reminders',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
          trailing: Switch(
            value: showAlerts,
            onChanged: (value) {
              widgetService.updateConfig(
                config.copyWith(showAlerts: value),
              );
            },
            activeThumbColor: colors.accent,
          ),
          onTap: () {
            widgetService.updateConfig(
              config.copyWith(showAlerts: !showAlerts),
            );
          },
        );
      },
    );
  }
}

/// Widget quick-add categories customization tile
class _WidgetQuickAddCategoriesTile extends StatelessWidget {
  final WidgetService widgetService;
  final LedgerifyColorScheme colors;

  const _WidgetQuickAddCategoriesTile({
    required this.widgetService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widgetService.configBox.listenable(),
      builder: (context, box, _) {
        final config = widgetService.config;
        final isAutoLearn = config.isAutoLearn;
        final categories = widgetService.getQuickAddCategories();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: Icon(
            Icons.grid_view_rounded,
            color: colors.textSecondary,
          ),
          title: Text(
            'Quick-add categories',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            isAutoLearn
                ? 'Auto (${categories.map((c) => c.displayName).join(', ')})'
                : categories.map((c) => c.displayName).join(', '),
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
          ),
          onTap: () => _showCategoryPicker(context, config, categories),
        );
      },
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetConfig config,
    List<ExpenseCategory> currentCategories,
  ) {
    final colors = LedgerifyColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => _CategoryPickerSheet(
        widgetService: widgetService,
        config: config,
        currentCategories: currentCategories,
        colors: colors,
      ),
    );
  }
}

/// Bottom sheet for picking quick-add categories
class _CategoryPickerSheet extends StatefulWidget {
  final WidgetService widgetService;
  final WidgetConfig config;
  final List<ExpenseCategory> currentCategories;
  final LedgerifyColorScheme colors;

  const _CategoryPickerSheet({
    required this.widgetService,
    required this.config,
    required this.currentCategories,
    required this.colors,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<ExpenseCategory> _selectedCategories;
  late bool _isAutoLearn;

  @override
  void initState() {
    super.initState();
    _isAutoLearn = widget.config.isAutoLearn;
    _selectedCategories = List.from(widget.currentCategories);
  }

  void _toggleCategory(ExpenseCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else if (_selectedCategories.length < 4) {
        _selectedCategories.add(category);
      }
    });
  }

  void _setAutoLearn(bool value) {
    setState(() {
      _isAutoLearn = value;
      if (value) {
        _selectedCategories = widget.widgetService.getQuickAddCategories();
      }
    });
  }

  void _save() {
    if (_isAutoLearn) {
      // Clear custom categories to enable auto-learn
      widget.widgetService.updateConfig(
        widget.config.copyWith(clearQuickAddCategories: true),
      );
    } else {
      // Save custom category selection
      widget.widgetService.updateConfig(
        widget.config.copyWith(
          quickAddCategories: _selectedCategories.map((c) => c.index).toList(),
        ),
      );
    }
    Navigator.pop(context);
  }

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
                  color: widget.colors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            LedgerifySpacing.verticalLg,

            // Title
            Text(
              'Quick-add categories',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: widget.colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Choose up to 4 categories for the widget',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: widget.colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalLg,

            // Auto-learn toggle
            InkWell(
              onTap: () => _setAutoLearn(!_isAutoLearn),
              borderRadius: LedgerifyRadius.borderRadiusMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LedgerifySpacing.sm,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isAutoLearn,
                      onChanged: (v) => _setAutoLearn(v ?? false),
                      activeColor: widget.colors.accent,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-learn from spending',
                            style: LedgerifyTypography.bodyLarge.copyWith(
                              color: widget.colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Shows your most-used categories',
                            style: LedgerifyTypography.bodySmall.copyWith(
                              color: widget.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_isAutoLearn) ...[
              LedgerifySpacing.verticalMd,
              Divider(color: widget.colors.surfaceHighlight),
              LedgerifySpacing.verticalMd,

              // Category grid
              Text(
                'Select categories (${_selectedCategories.length}/4)',
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: widget.colors.textSecondary,
                ),
              ),
              LedgerifySpacing.verticalSm,

              Wrap(
                spacing: LedgerifySpacing.sm,
                runSpacing: LedgerifySpacing.sm,
                children: ExpenseCategory.values.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  final canSelect =
                      isSelected || _selectedCategories.length < 4;

                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected
                              ? widget.colors.textPrimary
                              : widget.colors.textSecondary,
                        ),
                        LedgerifySpacing.horizontalXs,
                        Text(category.displayName),
                      ],
                    ),
                    selected: isSelected,
                    onSelected:
                        canSelect ? (_) => _toggleCategory(category) : null,
                    selectedColor: widget.colors.accent.withValues(alpha: 0.2),
                    checkmarkColor: widget.colors.accent,
                    labelStyle: LedgerifyTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? widget.colors.textPrimary
                          : (canSelect
                              ? widget.colors.textSecondary
                              : widget.colors.textTertiary),
                    ),
                    backgroundColor: widget.colors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? widget.colors.accent
                          : widget.colors.surfaceHighlight,
                    ),
                  );
                }).toList(),
              ),
            ],

            LedgerifySpacing.verticalXl,

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.colors.accent,
                  foregroundColor: widget.colors.background,
                  padding: const EdgeInsets.symmetric(
                    vertical: LedgerifySpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'Save',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: widget.colors.background,
                  ),
                ),
              ),
            ),

            LedgerifySpacing.verticalSm,
          ],
        ),
      ),
    );
  }
}

/// Widget sync now tile
class _WidgetSyncNowTile extends StatefulWidget {
  final WidgetService widgetService;
  final LedgerifyColorScheme colors;

  const _WidgetSyncNowTile({
    required this.widgetService,
    required this.colors,
  });

  @override
  State<_WidgetSyncNowTile> createState() => _WidgetSyncNowTileState();
}

class _WidgetSyncNowTileState extends State<_WidgetSyncNowTile> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      // Determine current theme
      final isDark = Theme.of(context).brightness == Brightness.dark;
      await widget.widgetService.syncDataImmediate(isDarkMode: isDark);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Widget synced',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: widget.colors.textPrimary,
              ),
            ),
            backgroundColor: widget.colors.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync failed',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: widget.colors.textPrimary,
              ),
            ),
            backgroundColor: widget.colors.surface,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.widgetService.configBox.listenable(),
      builder: (context, box, _) {
        final config = widget.widgetService.config;
        final lastSynced = config.lastSynced;

        String subtitleText;
        if (lastSynced == null) {
          subtitleText = 'Never synced';
        } else {
          final diff = DateTime.now().difference(lastSynced);
          if (diff.inMinutes < 1) {
            subtitleText = 'Synced just now';
          } else if (diff.inMinutes < 60) {
            subtitleText = 'Synced ${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            subtitleText = 'Synced ${diff.inHours}h ago';
          } else {
            subtitleText = 'Synced ${diff.inDays}d ago';
          }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.xs,
          ),
          leading: _isSyncing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.colors.accent),
                  ),
                )
              : Icon(
                  Icons.sync_rounded,
                  color: widget.colors.textSecondary,
                ),
          title: Text(
            'Sync now',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: widget.colors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: LedgerifyTypography.bodySmall.copyWith(
              color: widget.colors.textTertiary,
            ),
          ),
          onTap: _isSyncing ? null : _syncNow,
        );
      },
    );
  }
}
