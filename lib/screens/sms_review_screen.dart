import 'package:flutter/material.dart';
import '../models/sms_transaction.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../services/sms_transaction_service.dart';
import '../services/custom_category_service.dart';
import '../widgets/sms_review_header.dart';
import '../widgets/sms_review_tile.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/income_source_picker_sheet.dart';
import '../theme/ledgerify_theme.dart';

/// SMS Review Screen - Ledgerify Design Language
///
/// Main screen for reviewing and confirming imported SMS transactions.
/// Features:
/// - Summary header with pending counts and totals
/// - List of pending transactions with review tiles
/// - Batch actions (Confirm All, Skip All)
/// - Empty state when all transactions reviewed
class SmsReviewScreen extends StatefulWidget {
  final SmsTransactionService smsTransactionService;
  final CustomCategoryService customCategoryService;

  const SmsReviewScreen({
    super.key,
    required this.smsTransactionService,
    required this.customCategoryService,
  });

  @override
  State<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends State<SmsReviewScreen> {
  List<SmsTransaction> _pendingTransactions = [];
  bool _isLoading = false;
  bool _isProcessingBatch = false;
  Map<String, dynamic> _categoryOverrides =
      {}; // smsId -> ExpenseCategory or IncomeSource
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  /// Reload pending transactions from service
  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions =
          widget.smsTransactionService.getPendingTransactions();
      setState(() {
        _pendingTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Failed to load transactions');
    }
  }

  /// Confirm a single transaction (debit or credit)
  Future<void> _confirmTransaction(SmsTransaction transaction) async {
    if (_processingIds.contains(transaction.smsId)) return;

    setState(() {
      _processingIds.add(transaction.smsId);
    });

    try {
      if (transaction.isDebit) {
        final override = _categoryOverrides[transaction.smsId];
        final category = override is ExpenseCategory ? override : null;
        await widget.smsTransactionService.confirmAsExpense(
          transaction,
          category: category,
        );
      } else {
        final override = _categoryOverrides[transaction.smsId];
        final source = override is IncomeSource ? override : IncomeSource.other;
        await widget.smsTransactionService.confirmAsIncome(
          transaction,
          source: source,
        );
      }

      // Remove from local list and overrides
      setState(() {
        _pendingTransactions.removeWhere((t) => t.smsId == transaction.smsId);
        _categoryOverrides.remove(transaction.smsId);
        _processingIds.remove(transaction.smsId);
      });

      _showToast('Transaction confirmed');
    } catch (e) {
      setState(() {
        _processingIds.remove(transaction.smsId);
      });
      _showToast('Failed to confirm transaction');
    }
  }

  /// Skip a single transaction
  Future<void> _skipTransaction(SmsTransaction transaction) async {
    if (_processingIds.contains(transaction.smsId)) return;

    setState(() {
      _processingIds.add(transaction.smsId);
    });

    try {
      await widget.smsTransactionService.skipTransaction(transaction);

      // Remove from local list and overrides
      setState(() {
        _pendingTransactions.removeWhere((t) => t.smsId == transaction.smsId);
        _categoryOverrides.remove(transaction.smsId);
        _processingIds.remove(transaction.smsId);
      });

      _showToast('Transaction skipped');
    } catch (e) {
      setState(() {
        _processingIds.remove(transaction.smsId);
      });
      _showToast('Failed to skip transaction');
    }
  }

  /// Open category picker for debit transactions
  Future<void> _openCategoryPicker(SmsTransaction transaction) async {
    final currentOverride = _categoryOverrides[transaction.smsId];
    final selectedBuiltIn =
        currentOverride is ExpenseCategory ? currentOverride : null;

    final result = await CategoryPickerSheet.show(
      context,
      customCategoryService: widget.customCategoryService,
      selectedBuiltIn: selectedBuiltIn,
    );

    if (result != null && result.builtInCategory != null) {
      setState(() {
        _categoryOverrides[transaction.smsId] = result.builtInCategory;
      });
    }
  }

  /// Open source picker for credit transactions
  Future<void> _openSourcePicker(SmsTransaction transaction) async {
    final currentOverride = _categoryOverrides[transaction.smsId];
    final selectedSource =
        currentOverride is IncomeSource ? currentOverride : null;

    final result = await IncomeSourcePickerSheet.show(
      context,
      selectedSource: selectedSource,
    );

    if (result != null) {
      setState(() {
        _categoryOverrides[transaction.smsId] = result;
      });
    }
  }

  /// Confirm all pending transactions with confirmation dialog
  Future<void> _confirmAll() async {
    if (_pendingTransactions.isEmpty || _isProcessingBatch) return;

    final colors = LedgerifyColors.of(context);
    final debitCount = _pendingTransactions.where((t) => t.isDebit).length;
    final creditCount = _pendingTransactions.where((t) => t.isCredit).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Confirm All',
          style: LedgerifyTypography.headlineSmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will confirm $debitCount debit${debitCount == 1 ? '' : 's'} as expenses and $creditCount credit${creditCount == 1 ? '' : 's'} as income. Categories will be auto-assigned where not specified.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Confirm',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      // Build category overrides map for expenses
      final categoryOverrides = <String, ExpenseCategory>{};
      for (final entry in _categoryOverrides.entries) {
        if (entry.value is ExpenseCategory) {
          categoryOverrides[entry.key] = entry.value as ExpenseCategory;
        }
      }

      // Build source overrides map for incomes
      final sourceOverrides = <String, IncomeSource>{};
      for (final entry in _categoryOverrides.entries) {
        if (entry.value is IncomeSource) {
          sourceOverrides[entry.key] = entry.value as IncomeSource;
        }
      }

      // Confirm all debits as expenses
      final debits = _pendingTransactions.where((t) => t.isDebit).toList();
      await widget.smsTransactionService.confirmMultipleAsExpensesWithOverrides(
        debits,
        categoryOverrides: categoryOverrides,
      );

      // Confirm all credits as incomes
      final credits = _pendingTransactions.where((t) => t.isCredit).toList();
      await widget.smsTransactionService.confirmMultipleAsIncomes(
        credits,
        sourceOverrides: sourceOverrides,
      );

      // Clear local state
      setState(() {
        _pendingTransactions = [];
        _categoryOverrides = {};
        _isProcessingBatch = false;
      });

      _showToast('All transactions confirmed');
    } catch (e) {
      setState(() {
        _isProcessingBatch = false;
      });
      await _refreshTransactions();
      _showToast('Failed to confirm all transactions');
    }
  }

  /// Skip all pending transactions with confirmation dialog
  Future<void> _skipAll() async {
    if (_pendingTransactions.isEmpty || _isProcessingBatch) return;

    final colors = LedgerifyColors.of(context);
    final count = _pendingTransactions.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Skip All',
          style: LedgerifyTypography.headlineSmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will skip $count transaction${count == 1 ? '' : 's'}. Skipped transactions will not be added to your records but can be reviewed later.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Skip All',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.negative,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      await widget.smsTransactionService.skipMultiple(_pendingTransactions);

      // Clear local state
      setState(() {
        _pendingTransactions = [];
        _categoryOverrides = {};
        _isProcessingBatch = false;
      });

      _showToast('All transactions skipped');
    } catch (e) {
      setState(() {
        _isProcessingBatch = false;
      });
      await _refreshTransactions();
      _showToast('Failed to skip all transactions');
    }
  }

  /// Show a snackbar message
  void _showToast(String message) {
    if (!mounted) return;

    final colors = LedgerifyColors.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Transactions',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(colors)
          : _pendingTransactions.isEmpty
              ? _buildEmptyState(colors)
              : _buildContent(colors),
    );
  }

  Widget _buildLoadingState(LedgerifyColorScheme colors) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
      ),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: colors.accent,
                ),
              ),
              LedgerifySpacing.verticalXl,
              // Title
              Text(
                'All transactions reviewed',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              LedgerifySpacing.verticalSm,
              // Subtitle
              Text(
                'Your imported transactions have been confirmed or skipped.',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              LedgerifySpacing.verticalXl,
              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.background,
                    padding: const EdgeInsets.symmetric(
                      vertical: LedgerifySpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: LedgerifyRadius.borderRadiusMd,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: LedgerifyTypography.labelLarge.copyWith(
                      color: colors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LedgerifyColorScheme colors) {
    // Calculate summary stats
    final debitCount = _pendingTransactions.where((t) => t.isDebit).length;
    final creditCount = _pendingTransactions.where((t) => t.isCredit).length;
    final totalDebit = _pendingTransactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalCredit = _pendingTransactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            itemCount: _pendingTransactions.length + 1, // +1 for header
            itemBuilder: (context, index) {
              // Header at index 0
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: LedgerifySpacing.lg),
                  child: SmsReviewHeader(
                    pendingCount: _pendingTransactions.length,
                    debitCount: debitCount,
                    creditCount: creditCount,
                    totalDebitAmount: totalDebit,
                    totalCreditAmount: totalCredit,
                  ),
                );
              }

              // Transaction tiles
              final transaction = _pendingTransactions[index - 1];
              final override = _categoryOverrides[transaction.smsId];

              return Padding(
                padding: const EdgeInsets.only(bottom: LedgerifySpacing.md),
                child: SmsReviewTile(
                  transaction: transaction,
                  categoryOverride:
                      override is ExpenseCategory ? override : null,
                  sourceOverride: override is IncomeSource ? override : null,
                  isProcessing: _processingIds.contains(transaction.smsId),
                  onConfirm: () => _confirmTransaction(transaction),
                  onSkip: () => _skipTransaction(transaction),
                  onEditCategory: () => _openCategoryPicker(transaction),
                  onEditSource: () => _openSourcePicker(transaction),
                ),
              );
            },
          ),
        ),

        // Bottom action bar
        _buildBottomBar(colors),
      ],
    );
  }

  Widget _buildBottomBar(LedgerifyColorScheme colors) {
    return Container(
      padding: EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        top: LedgerifySpacing.lg,
        bottom: LedgerifySpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.surfaceHighlight,
            width: 1,
          ),
        ),
      ),
      child: _isProcessingBatch
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                ),
              ),
            )
          : Row(
              children: [
                // Confirm All button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.background,
                      padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: LedgerifyRadius.borderRadiusMd,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm All',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.background,
                      ),
                    ),
                  ),
                ),
                LedgerifySpacing.horizontalMd,
                // Skip All button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        vertical: LedgerifySpacing.md,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: LedgerifyRadius.borderRadiusMd,
                      ),
                      side: BorderSide(
                        color: colors.textTertiary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Skip All',
                      style: LedgerifyTypography.labelLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
