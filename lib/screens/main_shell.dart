import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_expense.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../services/recurring_expense_service.dart';
import '../services/theme_service.dart';
import '../theme/ledgerify_theme.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'recurring_list_screen.dart';
import 'settings_screen.dart';

/// Main Shell - Ledgerify Navigation Container
///
/// Provides bottom navigation between:
/// - Home (expense dashboard)
/// - Recurring (recurring expenses list)
/// - Analytics (spending analytics)
/// - Settings (app preferences)
///
/// Uses IndexedStack to preserve state across tab switches.
class MainShell extends StatefulWidget {
  final ExpenseService expenseService;
  final ThemeService themeService;
  final RecurringExpenseService recurringService;
  final BudgetService budgetService;

  const MainShell({
    super.key,
    required this.expenseService,
    required this.themeService,
    required this.recurringService,
    required this.budgetService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            expenseService: widget.expenseService,
            recurringService: widget.recurringService,
            onNavigateToRecurring: () => _switchTab(1),
          ),
          RecurringListScreen(
            recurringService: widget.recurringService,
            expenseService: widget.expenseService,
            isEmbedded: true, // No back button when embedded in tabs
          ),
          AnalyticsScreen(
            expenseService: widget.expenseService,
          ),
          SettingsScreen(
            themeService: widget.themeService,
          ),
        ],
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
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _currentIndex == 0,
                onTap: () => _switchTab(0),
                colors: colors,
              ),
              _NavItemWithBadge(
                icon: Icons.repeat_rounded,
                label: 'Recurring',
                isSelected: _currentIndex == 1,
                onTap: () => _switchTab(1),
                colors: colors,
                recurringService: widget.recurringService,
              ),
              _NavItem(
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                isSelected: _currentIndex == 2,
                onTap: () => _switchTab(2),
                colors: colors,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: _currentIndex == 3,
                onTap: () => _switchTab(3),
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single navigation item
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentMuted : Colors.transparent,
          borderRadius: LedgerifyRadius.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colors.accent : colors.textTertiary,
            ),
            if (isSelected) ...[
              LedgerifySpacing.horizontalSm,
              Text(
                label,
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Navigation item with badge for recurring count
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final LedgerifyColorScheme colors;
  final RecurringExpenseService recurringService;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.recurringService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: recurringService.box.listenable(),
      builder: (context, Box<RecurringExpense> box, _) {
        // Count items due within 7 days (efficient - no list allocation)
        final dueCount = recurringService.getUpcomingCount(days: 7);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: LedgerifySpacing.lg,
              vertical: LedgerifySpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentMuted : Colors.transparent,
              borderRadius: LedgerifyRadius.borderRadiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected ? colors.accent : colors.textTertiary,
                    ),
                    if (dueCount > 0 && !isSelected)
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
                ),
                if (isSelected) ...[
                  LedgerifySpacing.horizontalSm,
                  Text(
                    label,
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
