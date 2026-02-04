import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_expense.dart';
import '../services/budget_service.dart';
import '../services/category_default_service.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/goal_service.dart';
import '../services/income_service.dart';
import '../services/merchant_history_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/recurring_income_service.dart';
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
import '../services/tag_service.dart';
import '../services/theme_service.dart';
import '../theme/ledgerify_theme.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'plans_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

/// Main Shell - Ledgerify Navigation Container
///
/// Provides bottom navigation between:
/// - Dashboard
/// - Transactions
/// - Plans (budgets/recurring/goals)
/// - Analytics (spending analytics)
/// - Settings (app preferences)
///
/// Uses IndexedStack to preserve state across tab switches.
class MainShell extends StatefulWidget {
  final ExpenseService expenseService;
  final ThemeService themeService;
  final RecurringExpenseService recurringService;
  final BudgetService budgetService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final CategoryDefaultService categoryDefaultService;
  final MerchantHistoryService merchantHistoryService;
  final GoalService goalService;
  final IncomeService incomeService;
  final RecurringIncomeService recurringIncomeService;
  final NotificationService notificationService;
  final NotificationPreferencesService notificationPrefsService;
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;

  const MainShell({
    super.key,
    required this.expenseService,
    required this.themeService,
    required this.recurringService,
    required this.budgetService,
    required this.tagService,
    required this.customCategoryService,
    required this.categoryDefaultService,
    required this.merchantHistoryService,
    required this.goalService,
    required this.incomeService,
    required this.recurringIncomeService,
    required this.notificationService,
    required this.notificationPrefsService,
    required this.smsPermissionService,
    required this.smsTransactionService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Swipe detection threshold
  static const double _swipeThreshold = 50.0;
  double _dragStartX = 0;

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dragDistance = details.globalPosition.dx - _dragStartX;

    if (dragDistance.abs() > _swipeThreshold) {
      if (dragDistance > 0 && _currentIndex > 0) {
        // Swipe right - go to previous tab
        _switchTab(_currentIndex - 1);
      } else if (dragDistance < 0 && _currentIndex < 4) {
        // Swipe left - go to next tab
        _switchTab(_currentIndex + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              expenseService: widget.expenseService,
              recurringService: widget.recurringService,
              recurringIncomeService: widget.recurringIncomeService,
              tagService: widget.tagService,
              customCategoryService: widget.customCategoryService,
              categoryDefaultService: widget.categoryDefaultService,
              merchantHistoryService: widget.merchantHistoryService,
              incomeService: widget.incomeService,
              goalService: widget.goalService,
              onNavigateToRecurring: () => _switchTab(2),
            ),
            TransactionsScreen(
              expenseService: widget.expenseService,
              recurringService: widget.recurringService,
              recurringIncomeService: widget.recurringIncomeService,
              tagService: widget.tagService,
              customCategoryService: widget.customCategoryService,
              categoryDefaultService: widget.categoryDefaultService,
              merchantHistoryService: widget.merchantHistoryService,
              incomeService: widget.incomeService,
              goalService: widget.goalService,
            ),
            PlansScreen(
              expenseService: widget.expenseService,
              incomeService: widget.incomeService,
              budgetService: widget.budgetService,
              recurringExpenseService: widget.recurringService,
              recurringIncomeService: widget.recurringIncomeService,
              goalService: widget.goalService,
            ),
            AnalyticsScreen(
              expenseService: widget.expenseService,
              budgetService: widget.budgetService,
              incomeService: widget.incomeService,
            ),
            SettingsScreen(
              themeService: widget.themeService,
              tagService: widget.tagService,
              customCategoryService: widget.customCategoryService,
              notificationService: widget.notificationService,
              notificationPrefsService: widget.notificationPrefsService,
              smsPermissionService: widget.smsPermissionService,
              smsTransactionService: widget.smsTransactionService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(colors),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavigationBar(LedgerifyColorScheme colors) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _switchTab,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Transactions',
        ),
        NavigationDestination(
          icon: _PlansIconWithBadge(
            isSelected: _currentIndex == 2,
            colors: colors,
            recurringExpenseService: widget.recurringService,
            recurringIncomeService: widget.recurringIncomeService,
          ),
          label: 'Plans',
        ),
        const NavigationDestination(
          icon: Icon(Icons.analytics_rounded),
          label: 'Analytics',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _PlansIconWithBadge extends StatelessWidget {
  final bool isSelected;
  final LedgerifyColorScheme colors;
  final RecurringExpenseService recurringExpenseService;
  final RecurringIncomeService recurringIncomeService;

  const _PlansIconWithBadge({
    required this.isSelected,
    required this.colors,
    required this.recurringExpenseService,
    required this.recurringIncomeService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: recurringExpenseService.box.listenable(),
      builder: (context, Box<RecurringExpense> expenseBox, _) {
        return ValueListenableBuilder(
          valueListenable: recurringIncomeService.box.listenable(),
          builder: (context, incomeBox, _) {
            final dueCount = recurringExpenseService.getUpcomingCount(days: 7) +
                recurringIncomeService.getUpcomingCount(days: 7);
            final showBadge = dueCount > 0 && !isSelected;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.event_note_rounded),
                if (showBadge)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        dueCount > 9 ? '9+' : dueCount.toString(),
                        style: LedgerifyTypography.labelSmall.copyWith(
                          color: colors.background,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
