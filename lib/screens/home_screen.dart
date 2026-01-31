import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/category_breakdown_card.dart';
import 'add_expense_screen.dart';

/// Home Screen - Ledgerify Design Language
///
/// The main screen showing:
/// - Monthly total summary card
/// - Category breakdown (collapsible)
/// - Expense list grouped by date
/// - FAB to add new expense
class HomeScreen extends StatefulWidget {
  final ExpenseService expenseService;

  const HomeScreen({super.key, required this.expenseService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
    }
  }

  Future<void> _navigateToAddExpense([Expense? expenseToEdit]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expenseService: widget.expenseService,
          expenseToEdit: expenseToEdit,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expenseToEdit != null ? 'Expense updated' : 'Expense added',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: LedgerifyColors.textPrimary,
            ),
          ),
          backgroundColor: LedgerifyColors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LedgerifyColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusXl,
        ),
        title: Text(
          'Delete Expense?',
          style: LedgerifyTypography.headlineMedium,
        ),
        content: Text(
          'Are you sure you want to delete this ${CurrencyFormatter.format(expense.amount)} expense?',
          style: LedgerifyTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: LedgerifyColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: LedgerifyColors.negative,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.expenseService.deleteExpense(expense.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense deleted',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: LedgerifyColors.textPrimary,
            ),
          ),
          backgroundColor: LedgerifyColors.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerifyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Ledgerify',
          style: LedgerifyTypography.headlineMedium,
        ),
        centerTitle: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.expenseService.box.listenable(),
        builder: (context, Box<Expense> box, _) {
          final monthExpenses = widget.expenseService.getExpensesForMonth(
            _selectedMonth.year,
            _selectedMonth.month,
          );
          final monthTotal =
              widget.expenseService.calculateTotal(monthExpenses);
          final categoryBreakdown =
              widget.expenseService.getCategoryBreakdown(monthExpenses);

          return CustomScrollView(
            slivers: [
              // Monthly Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                  ),
                  child: MonthlySummaryCard(
                    selectedMonth: _selectedMonth,
                    total: monthTotal,
                    expenseCount: monthExpenses.length,
                    onPreviousMonth: _previousMonth,
                    onNextMonth: _nextMonth,
                  ),
                ),
              ),

              // Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: LedgerifySpacing.xl),
              ),

              // Category Breakdown Card
              if (monthExpenses.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.lg,
                    ),
                    child: CategoryBreakdownCard(
                      breakdown: categoryBreakdown,
                      total: monthTotal,
                    ),
                  ),
                ),

              // Spacing
              if (monthExpenses.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: LedgerifySpacing.xl),
                ),

              // Expense List or Empty State
              if (monthExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                _buildExpenseList(monthExpenses),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 88),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Expense',
          style: LedgerifyTypography.labelLarge.copyWith(
            color: LedgerifyColors.background,
          ),
        ),
        backgroundColor: LedgerifyColors.accent,
        foregroundColor: LedgerifyColors.background,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: LedgerifyColors.textTertiary,
            ),
            SizedBox(height: LedgerifySpacing.lg),
            Text(
              'No expenses yet',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: LedgerifyColors.textSecondary,
              ),
            ),
            SizedBox(height: LedgerifySpacing.sm),
            Text(
              'Add your first expense to start tracking',
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: LedgerifyColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = expenses[index];
          final showDateHeader =
              index == 0 || !_isSameDay(expense.date, expenses[index - 1].date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.only(
                    left: LedgerifySpacing.lg,
                    right: LedgerifySpacing.lg,
                    top: LedgerifySpacing.lg,
                    bottom: LedgerifySpacing.sm,
                  ),
                  child: Text(
                    DateFormatter.formatRelative(expense.date),
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: LedgerifyColors.textTertiary,
                    ),
                  ),
                ),
              // Expense tile
              ExpenseListTile(
                expense: expense,
                onTap: () => _navigateToAddExpense(expense),
                onDelete: () => _confirmDelete(expense),
              ),
            ],
          );
        },
        childCount: expenses.length,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
