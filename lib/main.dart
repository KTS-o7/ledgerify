import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/custom_category.dart';
import 'models/goal.dart';
import 'models/income.dart';
import 'models/notification_preferences.dart';
import 'models/recurring_income.dart';
import 'models/tag.dart';
import 'services/budget_service.dart';
import 'services/custom_category_service.dart';
import 'services/expense_service.dart';
import 'services/goal_service.dart';
import 'services/income_service.dart';
import 'services/notification_preferences_service.dart';
import 'services/notification_service.dart';
import 'services/recurring_expense_service.dart';
import 'services/recurring_income_service.dart';
import 'services/tag_service.dart';
import 'services/theme_service.dart';
import 'screens/main_shell.dart';
import 'theme/ledgerify_theme.dart';

/// Main entry point for the Ledgerify app.
///
/// Initializes Hive for local storage and launches the app.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final expenseService = ExpenseService();
  await expenseService.init();

  final themeService = ThemeService();
  await themeService.init();

  final recurringService = RecurringExpenseService();
  await recurringService.init();

  final budgetService = BudgetService();
  await budgetService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  // Register Hive adapters for Tag, CustomCategory, Goal, and Income
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(TagAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(CustomCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(GoalAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(IncomeSourceAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(GoalAllocationAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(IncomeAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(RecurringIncomeAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(NotificationPreferencesAdapter());
  }

  // Open Tag, CustomCategory, Goal, Income, RecurringIncome, and NotificationPreferences boxes
  final tagBox = await Hive.openBox<Tag>('tags');
  final customCategoryBox =
      await Hive.openBox<CustomCategory>('custom_categories');
  final goalBox = await Hive.openBox<Goal>('goals');
  final incomeBox = await Hive.openBox<Income>('incomes');
  final recurringIncomeBox =
      await Hive.openBox<RecurringIncome>('recurring_incomes');
  final notificationPrefsBox =
      await Hive.openBox<NotificationPreferences>('notification_preferences');

  // Create Tag, CustomCategory, Goal, Income, RecurringIncome, and NotificationPreferences services
  final tagService = TagService(tagBox);
  final customCategoryService = CustomCategoryService(customCategoryBox);
  final goalService = GoalService(goalBox);
  final incomeService = IncomeService(incomeBox, goalService);
  final recurringIncomeService = RecurringIncomeService(recurringIncomeBox);
  final notificationPrefsService =
      NotificationPreferencesService(notificationPrefsBox);

  // Wire up notification service with preferences
  notificationService.setPreferencesService(notificationPrefsService);

  // Wire up services for budget notifications
  expenseService.setBudgetServices(budgetService, notificationService);

  // Run the app first, then handle notifications
  runApp(LedgerifyApp(
    expenseService: expenseService,
    themeService: themeService,
    recurringService: recurringService,
    budgetService: budgetService,
    tagService: tagService,
    customCategoryService: customCategoryService,
    goalService: goalService,
    incomeService: incomeService,
    recurringIncomeService: recurringIncomeService,
    notificationService: notificationService,
    notificationPrefsService: notificationPrefsService,
  ));

  // Handle notifications and recurring items after first frame renders
  // This prevents blocking the initial app startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Request notification permission
    try {
      await notificationService.requestPermission();
      await notificationService.rescheduleAll();
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }

    // Generate due recurring expenses and incomes
    try {
      await recurringService.generateDueExpenses(expenseService);
      await recurringIncomeService.generateDueIncomes(incomeService);
    } catch (e) {
      debugPrint('Error generating recurring items: $e');
    }
  });
}

/// The root widget of the Ledgerify application.
///
/// Supports light and dark themes with system preference option.
/// Philosophy: Quiet Finance — calm, premium, trustworthy.
class LedgerifyApp extends StatelessWidget {
  final ExpenseService expenseService;
  final ThemeService themeService;
  final RecurringExpenseService recurringService;
  final BudgetService budgetService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;
  final GoalService goalService;
  final IncomeService incomeService;
  final RecurringIncomeService recurringIncomeService;
  final NotificationService notificationService;
  final NotificationPreferencesService notificationPrefsService;

  const LedgerifyApp({
    super.key,
    required this.expenseService,
    required this.themeService,
    required this.recurringService,
    required this.budgetService,
    required this.tagService,
    required this.customCategoryService,
    required this.goalService,
    required this.incomeService,
    required this.recurringIncomeService,
    required this.notificationService,
    required this.notificationPrefsService,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeService.themeMode,
      builder: (context, appThemeMode, _) {
        // Update system UI overlay based on theme
        _updateSystemUI(appThemeMode, context);

        return MaterialApp(
          title: 'Ledgerify',
          debugShowCheckedModeBanner: false,

          // Apply Ledgerify themes
          theme: LedgerifyTheme.lightTheme,
          darkTheme: LedgerifyTheme.darkTheme,
          themeMode: appThemeMode.themeMode,

          // Main shell with bottom navigation
          home: MainShell(
            expenseService: expenseService,
            themeService: themeService,
            recurringService: recurringService,
            budgetService: budgetService,
            tagService: tagService,
            customCategoryService: customCategoryService,
            goalService: goalService,
            incomeService: incomeService,
            recurringIncomeService: recurringIncomeService,
            notificationService: notificationService,
            notificationPrefsService: notificationPrefsService,
          ),
        );
      },
    );
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUI(AppThemeMode appThemeMode, BuildContext context) {
    // Determine if we're in dark mode
    final isDark = appThemeMode == AppThemeMode.dark ||
        (appThemeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    final colors = isDark ? LedgerifyColors.dark : LedgerifyColors.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
