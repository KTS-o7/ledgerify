import 'package:flutter/material.dart';
import '../models/recurring_expense.dart';
import '../services/recurring_expense_service.dart';
import '../theme/ledgerify_theme.dart';

/// Add/Edit Recurring Expense Screen - Ledgerify Design Language
///
/// A form screen for creating or editing a recurring expense template.
/// Features:
/// - Title input
/// - Amount input with currency prefix
/// - Category dropdown with icons
/// - Frequency picker with advanced options
/// - Start date picker
/// - Optional end date
/// - Note field
/// - Full-width primary action button
///
/// TODO: Implement full form in Phase 3
class AddRecurringScreen extends StatefulWidget {
  final RecurringExpenseService recurringService;
  final RecurringExpense? recurringToEdit;

  const AddRecurringScreen({
    super.key,
    required this.recurringService,
    this.recurringToEdit,
  });

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  bool get _isEditing => widget.recurringToEdit != null;

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
          _isEditing ? 'Edit Recurring' : 'Add Recurring',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LedgerifySpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: colors.textTertiary,
              ),
              SizedBox(height: LedgerifySpacing.lg),
              Text(
                'Coming in Phase 3',
                style: LedgerifyTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: LedgerifySpacing.sm),
              Text(
                'The add/edit form will be implemented next',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
