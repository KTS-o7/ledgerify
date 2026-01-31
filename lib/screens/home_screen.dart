import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/category_breakdown_card.dart';
import 'add_expense_screen.dart';

/// Home Screen - The main screen of the app.
///
/// Displays:
/// - Monthly total at the top
/// - Category breakdown (collapsible)
/// - Reverse chronological list of expenses
/// - FAB to add new expense
class HomeScreen extends StatefulWidget {
  final ExpenseService expenseService;

  const HomeScreen({super.key, required this.expenseService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Track the currently selected month for viewing
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  /// Navigate to previous month
  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  /// Navigate to next month
  void _nextMonth() {
    final now = DateTime.now();
    // Don't allow navigating to future months
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
        );
      });
    }
  }

  /// Navigate to Add Expense screen
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

    // If expense was added/edited, the list will auto-refresh via ValueListenableBuilder
    if (result == true && mounted) {
      // Optionally show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expenseToEdit != null ? 'Expense updated' : 'Expense added',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show delete confirmation dialog
  Future<void> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
          'Are you sure you want to delete this ${CurrencyFormatter.format(expense.amount)} expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.expenseService.deleteExpense(expense.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgerify'),
        centerTitle: true,
        elevation: 0,
      ),
      // Use ValueListenableBuilder to reactively rebuild when data changes
      body: ValueListenableBuilder(
        valueListenable: widget.expenseService.box.listenable(),
        builder: (context, Box<Expense> box, _) {
          // Get expenses for the selected month
          final monthExpenses = widget.expenseService.getExpensesForMonth(
            _selectedMonth.year,
            _selectedMonth.month,
          );
          final monthTotal = widget.expenseService.calculateTotal(
            monthExpenses,
          );
          final categoryBreakdown = widget.expenseService.getCategoryBreakdown(
            monthExpenses,
          );

          return Column(
            children: [
              // Month navigation and summary
              MonthlySummaryCard(
                selectedMonth: _selectedMonth,
                total: monthTotal,
                expenseCount: monthExpenses.length,
                onPreviousMonth: _previousMonth,
                onNextMonth: _nextMonth,
              ),

              // Category breakdown (only show if there are expenses)
              if (monthExpenses.isNotEmpty)
                CategoryBreakdownCard(
                  breakdown: categoryBreakdown,
                  total: monthTotal,
                ),

              // Expense list
              Expanded(
                child: monthExpenses.isEmpty
                    ? _buildEmptyState()
                    : _buildExpenseList(monthExpenses),
              ),
            ],
          );
        },
      ),
      // Floating action button to add new expense
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  /// Builds the empty state widget when no expenses exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first expense',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of expenses
  Widget _buildExpenseList(List<Expense> expenses) {
    // Group expenses by date for better visual separation
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88), // Space for FAB
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final showDateHeader =
            index == 0 || !_isSameDay(expense.date, expenses[index - 1].date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  DateFormatter.formatRelative(expense.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
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
    );
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
