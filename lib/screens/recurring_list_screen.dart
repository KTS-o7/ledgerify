import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_expense.dart';
import '../services/expense_service.dart';
import '../services/recurring_expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/recurring_expense_list_tile.dart';
import 'add_recurring_screen.dart';

/// Recurring Expenses List Screen - Ledgerify Design Language
///
/// Displays all recurring expense templates with:
/// - Active recurring expenses section
/// - Paused recurring expenses section (if any)
/// - Empty state when no recurring expenses exist
/// - FAB to add new recurring expense
class RecurringListScreen extends StatelessWidget {
  final RecurringExpenseService recurringService;
  final ExpenseService? expenseService;

  /// When true, removes back button (used when embedded in bottom nav)
  final bool isEmbedded;

  const RecurringListScreen({
    super.key,
    required this.recurringService,
    this.expenseService,
    this.isEmbedded = false,
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
        automaticallyImplyLeading: !isEmbedded,
        leading: isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
                color: colors.textPrimary,
              ),
        title: Text(
          'Recurring',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: recurringService.box.listenable(),
        builder: (context, Box<RecurringExpense> box, _) {
          // Single-pass categorization
          final categorized = recurringService.getCategorized();
          final activeItems = categorized.active;
          final pausedItems = categorized.paused;
          final endedItems = categorized.ended;

          if (activeItems.isEmpty &&
              pausedItems.isEmpty &&
              endedItems.isEmpty) {
            return _buildEmptyState(context, colors);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 88), // Space for FAB
            children: [
              // Active section
              if (activeItems.isNotEmpty) ...[
                _buildSectionHeader(
                    context, colors, 'Active', activeItems.length),
                ...activeItems.map((item) => _buildListTile(context, item)),
              ],

              // Paused section
              if (pausedItems.isNotEmpty) ...[
                SizedBox(height: LedgerifySpacing.lg),
                _buildSectionHeader(
                    context, colors, 'Paused', pausedItems.length),
                ...pausedItems.map((item) => _buildListTile(context, item)),
              ],

              // Ended section
              if (endedItems.isNotEmpty) ...[
                SizedBox(height: LedgerifySpacing.lg),
                _buildSectionHeader(
                    context, colors, 'Ended', endedItems.length),
                ...endedItems.map((item) => _buildListTile(context, item)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: colors.accent,
        foregroundColor: colors.background,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Builds the empty state view.
  Widget _buildEmptyState(BuildContext context, LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 64,
              color: colors.textTertiary,
            ),
            SizedBox(height: LedgerifySpacing.lg),
            Text(
              'No recurring expenses',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: LedgerifySpacing.sm),
            Text(
              'Add subscriptions, rent, or bills to track them automatically',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: LedgerifySpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _navigateToAdd(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Recurring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.xl,
                  vertical: LedgerifySpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header.
  Widget _buildSectionHeader(
    BuildContext context,
    LedgerifyColorScheme colors,
    String title,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: LedgerifyTypography.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: LedgerifySpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusSm,
            ),
            child: Text(
              count.toString(),
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list tile for a recurring expense.
  Widget _buildListTile(BuildContext context, RecurringExpense item) {
    return RecurringExpenseListTile(
      recurring: item,
      onTap: () => _navigateToEdit(context, item),
      onTogglePause: () => _togglePause(context, item),
      onDelete: () => _confirmDelete(context, item),
      onPayNow: expenseService != null ? () => _payNow(context, item) : null,
    );
  }

  /// Navigates to the add recurring screen.
  void _navigateToAdd(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringScreen(
          recurringService: recurringService,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recurring expense added',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: LedgerifyColors.of(context).accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Navigates to the edit recurring screen.
  void _navigateToEdit(BuildContext context, RecurringExpense item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringScreen(
          recurringService: recurringService,
          recurringToEdit: item,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recurring expense updated',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: LedgerifyColors.of(context).accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Pays a recurring expense now.
  void _payNow(BuildContext context, RecurringExpense item) async {
    if (expenseService == null) return;

    final colors = LedgerifyColors.of(context);

    // Clear any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final expense = await recurringService.payNow(item.id, expenseService!);

    if (expense != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} paid - ${CurrencyFormatter.format(expense.amount)}',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Toggles pause/resume state for a recurring expense.
  void _togglePause(BuildContext context, RecurringExpense item) async {
    final colors = LedgerifyColors.of(context);

    // Clear any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (item.isActive) {
      await recurringService.pause(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.title} paused',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              textColor: colors.accent,
              onPressed: () => recurringService.resume(item.id),
            ),
          ),
        );
      }
    } else {
      await recurringService.resume(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.title} resumed',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.accent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Shows confirmation dialog before deleting.
  void _confirmDelete(BuildContext context, RecurringExpense item) {
    final colors = LedgerifyColors.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Delete recurring expense?',
          style: LedgerifyTypography.headlineSmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will stop "${item.title}" from generating future expenses. '
          'Existing expenses will not be affected.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecurring(context, item);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: colors.negative),
            ),
          ),
        ],
      ),
    );
  }

  /// Deletes a recurring expense.
  void _deleteRecurring(BuildContext context, RecurringExpense item) async {
    final title = item.title;

    // Clear any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    await recurringService.delete(item.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$title deleted',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: LedgerifyColors.of(context).negative,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
