import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/custom_category.dart';
import 'models/goal.dart';
import 'models/tag.dart';
import 'services/budget_service.dart';
import 'services/custom_category_service.dart';
import 'services/expense_service.dart';
import 'services/goal_service.dart';
import 'services/notification_service.dart';
import 'services/recurring_expense_service.dart';
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

  // Register Hive adapters for Tag, CustomCategory, and Goal
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(TagAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(CustomCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(GoalAdapter());
  }

  // Open Tag, CustomCategory, and Goal boxes
  final tagBox = await Hive.openBox<Tag>('tags');
  final customCategoryBox =
      await Hive.openBox<CustomCategory>('custom_categories');
  final goalBox = await Hive.openBox<Goal>('goals');

  // Create Tag, CustomCategory, and Goal services
  final tagService = TagService(tagBox);
  final customCategoryService = CustomCategoryService(customCategoryBox);
  final goalService = GoalService(goalBox);

  // Wire up services for budget notifications
  expenseService.setBudgetServices(budgetService, notificationService);

  // Generate due recurring expenses on app open
  await recurringService.generateDueExpenses(expenseService);

  // Run the app
  runApp(LedgerifyApp(
    expenseService: expenseService,
    themeService: themeService,
    recurringService: recurringService,
    budgetService: budgetService,
    tagService: tagService,
    customCategoryService: customCategoryService,
    goalService: goalService,
  ));
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

  const LedgerifyApp({
    super.key,
    required this.expenseService,
    required this.themeService,
    required this.recurringService,
    required this.budgetService,
    required this.tagService,
    required this.customCategoryService,
    required this.goalService,
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
