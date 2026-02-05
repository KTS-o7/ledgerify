import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sms_transaction.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/sms_transaction_service.dart';
import '../services/tag_service.dart';
import '../services/theme_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

class NerdStatsScreen extends StatefulWidget {
  final ThemeService themeService;
  final ExpenseService expenseService;
  final IncomeService incomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final SmsTransactionService smsTransactionService;

  const NerdStatsScreen({
    super.key,
    required this.themeService,
    required this.expenseService,
    required this.incomeService,
    required this.tagService,
    required this.customCategoryService,
    required this.smsTransactionService,
  });

  @override
  State<NerdStatsScreen> createState() => _NerdStatsScreenState();
}

class _NerdStatsScreenState extends State<NerdStatsScreen> {
  late Future<_NerdStatsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NerdStatsData> _load() async {
    final boxStats = <_BoxStat>[];

    Future<Box<E>?> openBoxIfNeeded<E>(String name) async {
      try {
        if (Hive.isBoxOpen(name)) return Hive.box<E>(name);
        return await Hive.openBox<E>(name);
      } catch (_) {
        return null;
      }
    }

    Future<_BoxStat?> boxStat(String name) async {
      final box = await openBoxIfNeeded(name);
      if (box == null) return null;
      final path = box.path;
      final bytes = path == null ? null : await _safeFileSize(path);
      return _BoxStat(
        name: name,
        entries: box.length,
        bytes: bytes,
      );
    }

    Future<int> boxLength(String name) async {
      final box = await openBoxIfNeeded(name);
      return box?.length ?? 0;
    }

    Future<(int, int)> smsCounts() async {
      final smsBox = await openBoxIfNeeded<SmsTransaction>('sms_transactions');
      if (smsBox == null) return (0, 0);
      var pending = 0;
      for (final t in smsBox.values) {
        if (t.status == SmsTransactionStatus.pending) pending += 1;
      }
      return (smsBox.length, pending);
    }

    // Core boxes (open if needed for accurate stats)
    final expenseCount = await boxLength('expenses');
    final incomeCount = await boxLength('incomes');
    final tagCount = await boxLength('tags');
    final customCategoryCount = await boxLength('custom_categories');
    final (smsTotalCount, smsPendingCount) = await smsCounts();

    // Include storage stats for known boxes
    const knownBoxes = <String>[
      'expenses',
      'incomes',
      'tags',
      'custom_categories',
      'sms_transactions',
      'settings',
      'budgets',
      'goals',
      'recurring_expenses',
      'recurring_incomes',
      'merchant_history',
      'notification_preferences',
      'category_defaults',
    ];

    for (final name in knownBoxes) {
      final stat = await boxStat(name);
      if (stat != null) boxStats.add(stat);
    }

    boxStats.sort((a, b) => a.name.compareTo(b.name));

    final totalBytes = boxStats.fold<int>(
      0,
      (sum, b) => sum + (b.bytes ?? 0),
    );

    return _NerdStatsData(
      generatedAt: DateTime.now(),
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      tagCount: tagCount,
      customCategoryCount: customCategoryCount,
      smsPendingCount: smsPendingCount,
      smsTotalCount: smsTotalCount,
      themeMode: widget.themeService.themeMode.value,
      useDynamicColor: widget.themeService.useDynamicColor.value,
      boxes: boxStats,
      totalBytes: totalBytes,
    );
  }

  Future<int?> _safeFileSize(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Stats for nerds',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<_NerdStatsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: colors.accent,
                strokeWidth: 2,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load stats',
                      style: LedgerifyTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    LedgerifySpacing.verticalSm,
                    Text(
                      snapshot.error.toString(),
                      style: LedgerifyTypography.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    LedgerifySpacing.verticalMd,
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _future = _load();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Could not load stats',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            children: [
              _buildQuickStats(colors, data),
              LedgerifySpacing.verticalLg,
              _buildThemeStats(colors, data),
              LedgerifySpacing.verticalLg,
              _buildStorageStats(colors, data),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(LedgerifyColorScheme colors, _NerdStatsData data) {
    return _Card(
      colors: colors,
      title: 'Counts',
      child: Column(
        children: [
          _RowStat(
            label: 'Expenses',
            value: data.expenseCount.toString(),
            colors: colors,
          ),
          _RowStat(
            label: 'Income',
            value: data.incomeCount.toString(),
            colors: colors,
          ),
          _RowStat(
            label: 'Tags',
            value: data.tagCount.toString(),
            colors: colors,
          ),
          _RowStat(
            label: 'Custom categories',
            value: data.customCategoryCount.toString(),
            colors: colors,
          ),
          _RowStat(
            label: 'SMS pending',
            value: data.smsPendingCount.toString(),
            colors: colors,
          ),
          _RowStat(
            label: 'SMS total',
            value: data.smsTotalCount.toString(),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStats(LedgerifyColorScheme colors, _NerdStatsData data) {
    return _Card(
      colors: colors,
      title: 'Theme',
      child: Column(
        children: [
          _RowStat(
            label: 'Mode',
            value: data.themeMode.displayName,
            colors: colors,
          ),
          _RowStat(
            label: 'Material You',
            value: data.useDynamicColor ? 'On' : 'Off',
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStats(LedgerifyColorScheme colors, _NerdStatsData data) {
    return _Card(
      colors: colors,
      title: 'Storage',
      subtitle:
          'Hive box sizes on disk • updated ${DateFormatter.formatRelative(data.generatedAt)}',
      child: Column(
        children: [
          _RowStat(
            label: 'Total (known boxes)',
            value: _formatBytes(data.totalBytes),
            colors: colors,
          ),
          const Divider(height: 24),
          ...data.boxes.map((b) {
            final size = b.bytes == null ? 'N/A' : _formatBytes(b.bytes!);
            return _RowStat(
              label: b.name,
              value: '$size • ${b.entries} items',
              colors: colors,
            );
          }),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final precision = unit == 0 ? 0 : (unit == 1 ? 1 : 2);
    return '${size.toStringAsFixed(precision)} ${units[unit]}';
  }
}

class _Card extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Card({
    required this.colors,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            LedgerifySpacing.verticalXs,
            Text(
              subtitle!,
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
          LedgerifySpacing.verticalMd,
          child,
        ],
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final String label;
  final String value;
  final LedgerifyColorScheme colors;

  const _RowStat({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NerdStatsData {
  final DateTime generatedAt;
  final int expenseCount;
  final int incomeCount;
  final int tagCount;
  final int customCategoryCount;
  final int smsPendingCount;
  final int smsTotalCount;
  final AppThemeMode themeMode;
  final bool useDynamicColor;

  final List<_BoxStat> boxes;
  final int totalBytes;

  const _NerdStatsData({
    required this.generatedAt,
    required this.expenseCount,
    required this.incomeCount,
    required this.tagCount,
    required this.customCategoryCount,
    required this.smsPendingCount,
    required this.smsTotalCount,
    required this.themeMode,
    required this.useDynamicColor,
    required this.boxes,
    required this.totalBytes,
  });
}

class _BoxStat {
  final String name;
  final int entries;
  final int? bytes;

  const _BoxStat({
    required this.name,
    required this.entries,
    required this.bytes,
  });
}
