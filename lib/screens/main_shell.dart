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
import 'goals_screen.dart';
import 'home_screen.dart';
import 'recurring_list_screen.dart';
import 'settings_screen.dart';

/// Main Shell - Ledgerify Navigation Container
///
/// Provides bottom navigation between:
/// - Home (expense dashboard)
/// - Recurring (recurring expenses list)
/// - Analytics (spending analytics)
/// - Goals (savings goals)
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
              onNavigateToRecurring: () => _switchTab(1),
            ),
            RecurringListScreen(
              recurringExpenseService: widget.recurringService,
              recurringIncomeService: widget.recurringIncomeService,
              expenseService: widget.expenseService,
              incomeService: widget.incomeService,
              isEmbedded: true,
            ),
            AnalyticsScreen(
              expenseService: widget.expenseService,
              budgetService: widget.budgetService,
              incomeService: widget.incomeService,
            ),
            GoalsScreen(
              goalService: widget.goalService,
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
      bottomNavigationBar: _buildBottomNav(colors),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBottomNav(LedgerifyColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.sm,
            vertical: LedgerifySpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () => _switchTab(0),
                  colors: colors,
                ),
              ),
              Expanded(
                child: _NavItemWithBadge(
                  icon: Icons.repeat_rounded,
                  label: 'Recurring',
                  isSelected: _currentIndex == 1,
                  onTap: () => _switchTab(1),
                  colors: colors,
                  recurringExpenseService: widget.recurringService,
                  recurringIncomeService: widget.recurringIncomeService,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: _currentIndex == 2,
                  onTap: () => _switchTab(2),
                  colors: colors,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.flag_rounded,
                  label: 'Goals',
                  isSelected: _currentIndex == 3,
                  onTap: () => _switchTab(3),
                  colors: colors,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: _currentIndex == 4,
                  onTap: () => _switchTab(4),
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single navigation item - icon only, equal width
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final LedgerifyColorScheme colors;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: LedgerifySpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
                vertical: LedgerifySpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentMuted : Colors.transparent,
                borderRadius: LedgerifyRadius.borderRadiusFull,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? colors.accent : colors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: LedgerifyTypography.labelSmall.copyWith(
                color: isSelected ? colors.accent : colors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item with badge for recurring count
///
/// Optimized to only rebuild the badge when recurring data changes.
/// The static icon and label are preserved via ValueListenableBuilder's child parameter.
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final LedgerifyColorScheme colors;
  final RecurringExpenseService recurringExpenseService;
  final RecurringIncomeService recurringIncomeService;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.recurringExpenseService,
    required this.recurringIncomeService,
  });

  @override
  Widget build(BuildContext context) {
    // Static icon that doesn't depend on dueCount
    final staticIcon = Icon(
      icon,
      size: 24,
      color: isSelected ? colors.accent : colors.textTertiary,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: LedgerifySpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: LedgerifySpacing.lg,
                vertical: LedgerifySpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentMuted : Colors.transparent,
                borderRadius: LedgerifyRadius.borderRadiusFull,
              ),
              // Only the Stack with badge rebuilds when recurring data changes
              // Listen to both expense and income boxes
              child: ValueListenableBuilder(
                valueListenable: recurringExpenseService.box.listenable(),
                builder: (context, Box<RecurringExpense> expenseBox, child) {
                  return ValueListenableBuilder(
                    valueListenable: recurringIncomeService.box.listenable(),
                    builder: (context, incomeBox, child) {
                      // Count both recurring expenses and recurring income
                      final dueCount =
                          recurringExpenseService.getUpcomingCount(days: 7) +
                              recurringIncomeService.getUpcomingCount(days: 7);
                      final showBadge = dueCount > 0 && !isSelected;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Static icon passed through child parameter
                          child!,
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
                                  style:
                                      LedgerifyTypography.labelSmall.copyWith(
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
                    // Static icon preserved across rebuilds
                    child: child,
                  );
                },
                // Static icon preserved across rebuilds
                child: staticIcon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: LedgerifyTypography.labelSmall.copyWith(
                color: isSelected ? colors.accent : colors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
