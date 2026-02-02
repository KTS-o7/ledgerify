import 'package:flutter/material.dart';
import '../models/sms_transaction.dart';
import '../services/custom_category_service.dart';
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import 'sms_review_screen.dart';

/// Screen for importing transactions from SMS.
///
/// Handles permission requests and displays import progress.
class SmsImportScreen extends StatefulWidget {
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
  final CustomCategoryService customCategoryService;

  const SmsImportScreen({
    super.key,
    required this.smsPermissionService,
    required this.smsTransactionService,
    required this.customCategoryService,
  });

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;
  List<SmsTransaction>? _importedTransactions;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final granted = await widget.smsPermissionService.isGranted();
      setState(() {
        _hasPermission = granted;
      });
    } catch (e) {
      // Permission check failed - likely plugin not properly registered
      // This can happen on hot reload; user should restart the app
      debugPrint('Permission check failed: $e');
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Please restart the app to enable SMS features';
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await widget.smsPermissionService.getStatus();

      if (status == SmsPermissionStatus.permanentlyDenied) {
        // Need to open settings
        final opened = await widget.smsPermissionService.openSettings();
        if (!opened) {
          setState(() {
            _errorMessage = 'Could not open settings';
            _isLoading = false;
          });
        }
        return;
      }

      final granted = await widget.smsPermissionService.requestPermission();

      setState(() {
        _hasPermission = granted;
        _isLoading = false;
        if (!granted) {
          _errorMessage = 'SMS permission is required to import transactions';
        }
      });
    } catch (e) {
      debugPrint('Permission request failed: $e');
      setState(() {
        _errorMessage = 'Please restart the app to enable SMS features';
        _isLoading = false;
      });
    }
  }

  Future<void> _startImport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _importedTransactions = null;
    });

    try {
      // Import from last 30 days
      final since = DateTime.now().subtract(const Duration(days: 30));
      final imported = await widget.smsTransactionService.importFromInbox(
        since: since,
        limit: 500,
      );

      setState(() {
        _importedTransactions = imported;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to import: ${e.toString()}';
        _isLoading = false;
      });
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SMS Import',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        child: _buildContent(colors),
      ),
    );
  }

  Widget _buildContent(LedgerifyColorScheme colors) {
    if (_isLoading) {
      return _buildLoadingState(colors);
    }

    if (!_hasPermission) {
      return _buildPermissionRequest(colors);
    }

    if (_importedTransactions != null) {
      return _buildImportResults(colors);
    }

    return _buildReadyToImport(colors);
  }

  Widget _buildLoadingState(LedgerifyColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.accent,
            strokeWidth: 2,
          ),
          LedgerifySpacing.verticalLg,
          Text(
            'Scanning messages...',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest(LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms_rounded,
              size: 64,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalXl,
            Text(
              'SMS Permission Required',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'Ledgerify needs access to your SMS to automatically detect and import bank transactions.',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              LedgerifySpacing.verticalMd,
              Text(
                _errorMessage!,
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.negative,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            LedgerifySpacing.verticalXl,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _requestPermission,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  padding:
                      const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
                  shape: LedgerifyRadius.shapeMd,
                ),
                child: Text(
                  'Grant Permission',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: colors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyToImport(LedgerifyColorScheme colors) {
    final pendingCount = widget.smsTransactionService.pendingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Container(
          width: double.infinity,
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
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.accent,
                    size: 20,
                  ),
                  LedgerifySpacing.horizontalSm,
                  Text(
                    'Permission Granted',
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              LedgerifySpacing.verticalMd,
              Text(
                pendingCount > 0
                    ? 'You have $pendingCount pending transaction${pendingCount == 1 ? '' : 's'} to review.'
                    : 'Ready to scan your SMS for bank transactions.',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        LedgerifySpacing.verticalXl,

        // Review Pending button (if there are pending transactions)
        if (pendingCount > 0) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SmsReviewScreen(
                      smsTransactionService: widget.smsTransactionService,
                      customCategoryService: widget.customCategoryService,
                    ),
                  ),
                ).then((_) {
                  // Refresh pending count when returning
                  setState(() {});
                });
              },
              icon: const Icon(Icons.rate_review_rounded),
              label: Text('Review $pendingCount Pending'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                padding:
                    const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
                shape: LedgerifyRadius.shapeMd,
              ),
            ),
          ),
          LedgerifySpacing.verticalMd,
        ],

        // Import button
        SizedBox(
          width: double.infinity,
          child: pendingCount > 0
              ? OutlinedButton.icon(
                  onPressed: _startImport,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Scan for New SMS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.surfaceHighlight),
                    padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md),
                    shape: LedgerifyRadius.shapeMd,
                  ),
                )
              : FilledButton.icon(
                  onPressed: _startImport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Import from SMS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.background,
                    padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md),
                    shape: LedgerifyRadius.shapeMd,
                  ),
                ),
        ),

        LedgerifySpacing.verticalMd,

        // Info text
        Text(
          'Scans the last 30 days of SMS messages for bank transactions.',
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImportResults(LedgerifyColorScheme colors) {
    final transactions = _importedTransactions!;
    final debitCount = transactions.where((t) => t.isDebit).length;
    final creditCount = transactions.where((t) => t.isCredit).length;
    final totalAmount = transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final pendingCount = widget.smsTransactionService.pendingCount;
    final hasNewTransactions = transactions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results card
        Container(
          width: double.infinity,
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
                  Icon(
                    hasNewTransactions
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: hasNewTransactions
                        ? colors.accent
                        : colors.textTertiary,
                    size: 24,
                  ),
                  LedgerifySpacing.horizontalSm,
                  Text(
                    hasNewTransactions
                        ? 'Import Complete'
                        : 'No New Transactions',
                    style: LedgerifyTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              LedgerifySpacing.verticalLg,
              if (hasNewTransactions) ...[
                _ResultRow(
                  label: 'New transactions found',
                  value: '${transactions.length}',
                  colors: colors,
                ),
                LedgerifySpacing.verticalSm,
                _ResultRow(
                  label: 'Expenses (debits)',
                  value: '$debitCount',
                  colors: colors,
                ),
                LedgerifySpacing.verticalSm,
                _ResultRow(
                  label: 'Income (credits)',
                  value: '$creditCount',
                  colors: colors,
                ),
                LedgerifySpacing.verticalSm,
                _ResultRow(
                  label: 'Total expense amount',
                  value: CurrencyFormatter.format(totalAmount),
                  colors: colors,
                  isHighlighted: true,
                ),
              ] else ...[
                Text(
                  'All SMS from the last 30 days have already been imported.',
                  style: LedgerifyTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (pendingCount > 0) ...[
                LedgerifySpacing.verticalMd,
                Container(
                  padding: const EdgeInsets.all(LedgerifySpacing.md),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions_rounded,
                        color: colors.accent,
                        size: 20,
                      ),
                      LedgerifySpacing.horizontalSm,
                      Expanded(
                        child: Text(
                          '$pendingCount transaction${pendingCount == 1 ? '' : 's'} pending review',
                          style: LedgerifyTypography.labelMedium.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        LedgerifySpacing.verticalXl,

        // Review button (show if there are pending transactions)
        if (pendingCount > 0) ...[
          Text(
            hasNewTransactions
                ? 'Review your imported transactions to confirm or skip them.'
                : 'You have pending transactions from previous imports.',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          LedgerifySpacing.verticalLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SmsReviewScreen(
                      smsTransactionService: widget.smsTransactionService,
                      customCategoryService: widget.customCategoryService,
                    ),
                  ),
                ).then((_) {
                  // Refresh state when returning
                  setState(() {});
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                padding:
                    const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
                shape: LedgerifyRadius.shapeMd,
              ),
              child: Text(
                  'Review $pendingCount Transaction${pendingCount == 1 ? '' : 's'}'),
            ),
          ),
          LedgerifySpacing.verticalMd,
        ],

        // Scan again / Done button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                pendingCount > 0 ? _startImport : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.surfaceHighlight),
              padding:
                  const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
              shape: LedgerifyRadius.shapeMd,
            ),
            child: Text(pendingCount > 0 ? 'Scan Again' : 'Done'),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final LedgerifyColorScheme colors;
  final bool isHighlighted;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isHighlighted
                  ? LedgerifyTypography.amountMedium
                  : LedgerifyTypography.bodyMedium)
              .copyWith(
            color: isHighlighted ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
