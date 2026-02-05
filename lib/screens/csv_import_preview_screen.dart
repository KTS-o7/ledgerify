import 'package:flutter/material.dart';
import '../services/transaction_csv_service.dart';
import '../theme/ledgerify_theme.dart';

class CsvImportPreviewScreen extends StatefulWidget {
  final TransactionCsvService csvService;
  final CsvImportPreview preview;
  final String? sourceLabel;

  const CsvImportPreviewScreen({
    super.key,
    required this.csvService,
    required this.preview,
    this.sourceLabel,
  });

  @override
  State<CsvImportPreviewScreen> createState() => _CsvImportPreviewScreenState();
}

class _CsvImportPreviewScreenState extends State<CsvImportPreviewScreen> {
  bool _isImporting = false;

  Future<void> _import() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final result = await widget.csvService.applyImport(widget.preview);
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isImporting = false);

      final colors = LedgerifyColors.of(context);
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
    final colors = LedgerifyColors.of(context);
    final preview = widget.preview;

    final importCount = preview.toImport.length;
    final hasErrors = preview.errorCount > 0;
    final canImport = !_isImporting && importCount > 0 && !hasErrors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Import CSV',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        children: [
          _buildSummaryCard(colors),
          LedgerifySpacing.verticalLg,
          if (preview.tagsToCreate.isNotEmpty ||
              preview.customCategoriesToCreate.isNotEmpty)
            _buildCreatesCard(colors),
          if (preview.tagsToCreate.isNotEmpty ||
              preview.customCategoriesToCreate.isNotEmpty)
            LedgerifySpacing.verticalLg,
          _buildIssuesCard(colors),
          const SizedBox(height: 96),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LedgerifySpacing.lg,
            LedgerifySpacing.sm,
            LedgerifySpacing.lg,
            LedgerifySpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canImport ? _import : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                padding: const EdgeInsets.symmetric(
                  vertical: LedgerifySpacing.md,
                ),
                shape: LedgerifyRadius.shapeMd,
              ),
              child: _isImporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.background),
                      ),
                    )
                  : Text(
                      hasErrors
                          ? 'Fix errors to import'
                          : 'Import $importCount transaction${importCount == 1 ? '' : 's'}',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.background,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(LedgerifyColorScheme colors) {
    final preview = widget.preview;

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sourceLabel != null && widget.sourceLabel!.isNotEmpty) ...[
            Text(
              widget.sourceLabel!,
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalSm,
          ],
          _MetricRow(
            label: 'Rows',
            value: preview.totalDataRows.toString(),
            colors: colors,
          ),
          LedgerifySpacing.verticalXs,
          _MetricRow(
            label: 'Ready to import',
            value: preview.toImport.length.toString(),
            colors: colors,
            valueColor:
                preview.toImport.isEmpty ? colors.textSecondary : colors.accent,
          ),
          if (preview.skippedExisting > 0) ...[
            LedgerifySpacing.verticalXs,
            _MetricRow(
              label: 'Skipped (existing)',
              value: preview.skippedExisting.toString(),
              colors: colors,
            ),
          ],
          if (preview.warningCount > 0) ...[
            LedgerifySpacing.verticalXs,
            _MetricRow(
              label: 'Warnings',
              value: preview.warningCount.toString(),
              colors: colors,
              valueColor: colors.warning,
            ),
          ],
          if (preview.errorCount > 0) ...[
            LedgerifySpacing.verticalXs,
            _MetricRow(
              label: 'Errors',
              value: preview.errorCount.toString(),
              colors: colors,
              valueColor: colors.negative,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreatesCard(LedgerifyColorScheme colors) {
    final preview = widget.preview;
    final tagCount = preview.tagsToCreate.length;
    final categoryCount = preview.customCategoriesToCreate.length;

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
            'Will create',
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          LedgerifySpacing.verticalSm,
          if (categoryCount > 0)
            Text(
              '$categoryCount custom categor${categoryCount == 1 ? 'y' : 'ies'}',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          if (tagCount > 0)
            Text(
              '$tagCount tag${tagCount == 1 ? '' : 's'}',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssuesCard(LedgerifyColorScheme colors) {
    final issues = widget.preview.issues;
    final visibleIssues = issues.take(30).toList();

    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Checks',
                style: LedgerifyTypography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${issues.length}',
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          LedgerifySpacing.verticalSm,
          if (issues.isEmpty)
            Text(
              'No issues found.',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            ...visibleIssues.map((issue) {
              final color = issue.severity == CsvIssueSeverity.error
                  ? colors.negative
                  : colors.warning;
              final label = issue.severity == CsvIssueSeverity.error
                  ? 'Error'
                  : 'Warning';

              return Padding(
                padding: const EdgeInsets.only(bottom: LedgerifySpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LedgerifySpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: LedgerifyRadius.borderRadiusSm,
                      ),
                      child: Text(
                        label,
                        style: LedgerifyTypography.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    LedgerifySpacing.horizontalSm,
                    Expanded(
                      child: Text(
                        'Row ${issue.rowNumber}: ${issue.message}',
                        style: LedgerifyTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (issues.length > visibleIssues.length)
            Text(
              'Showing ${visibleIssues.length} of ${issues.length} issues.',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final LedgerifyColorScheme colors;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: valueColor ?? colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
