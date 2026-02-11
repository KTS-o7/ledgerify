import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:home_widget/home_widget.dart';
import 'models/custom_category.dart';
import 'models/expense.dart';
import 'models/goal.dart';
import 'models/income.dart';
import 'models/merchant_history.dart';
import 'models/notification_preferences.dart';
import 'models/recurring_income.dart';
import 'models/sms_transaction.dart';
import 'models/tag.dart';
import 'services/budget_service.dart';
import 'services/category_default_service.dart';
import 'services/custom_category_service.dart';
import 'services/expense_service.dart';
import 'services/goal_service.dart';
import 'services/income_service.dart';
import 'services/merchant_history_service.dart';
import 'services/notification_preferences_service.dart';
import 'services/notification_service.dart';
import 'services/recurring_expense_service.dart';
import 'services/recurring_income_service.dart';
import 'services/sms_permission_service.dart';
import 'services/sms_service.dart';
import 'services/sms_transaction_service.dart';
import 'services/tag_service.dart';
import 'services/theme_service.dart';
import 'services/transaction_parsing_service.dart';
import 'services/widget_service.dart';
import 'screens/main_shell.dart';
import 'screens/add_expense_screen.dart';
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

  // Initialize ExpenseService first - it calls Hive.initFlutter and registers core adapters
  final expenseService = ExpenseService();
  await expenseService.init();

  // Register Hive adapters for remaining models (after Hive is initialized)
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
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(MerchantHistoryAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(SmsTransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(SmsTransactionStatusAdapter());
  }

  // Initialize independent services in parallel
  final themeService = ThemeService();
  final recurringService = RecurringExpenseService();
  final budgetService = BudgetService();
  final notificationService = NotificationService();
  final categoryDefaultService = CategoryDefaultService();
  final merchantHistoryService = MerchantHistoryService();
  final widgetService = WidgetService();

  final smsPermissionService = SmsPermissionService();
  final transactionParsingService = TransactionParsingService();
  final smsService = SmsService(
    permissionService: smsPermissionService,
    parsingService: transactionParsingService,
  );

  // Compaction strategy: compact when deleted entries exceed 20% of total
  bool compactWhen(int entries, int deletedEntries) =>
      deletedEntries > entries * 0.2;

  // Parallel initialization of services and box opening
  await Future.wait([
    themeService.init(),
    recurringService.init(),
    budgetService.init(),
    notificationService.init(),
    categoryDefaultService.init(),
    merchantHistoryService.init(),
    widgetService.init(),
    // Open boxes in parallel
    Hive.openBox<Tag>('tags'),
    Hive.openBox<CustomCategory>('custom_categories'),
    Hive.openBox<Goal>('goals'),
    Hive.openBox<Income>('incomes', compactionStrategy: compactWhen),
    Hive.openBox<RecurringIncome>('recurring_incomes'),
    Hive.openBox<NotificationPreferences>('notification_preferences'),
  ]);

  // Retrieve opened boxes
  final tagBox = Hive.box<Tag>('tags');
  final customCategoryBox = Hive.box<CustomCategory>('custom_categories');
  final goalBox = Hive.box<Goal>('goals');
  final incomeBox = Hive.box<Income>('incomes');
  final recurringIncomeBox = Hive.box<RecurringIncome>('recurring_incomes');
  final notificationPrefsBox =
      Hive.box<NotificationPreferences>('notification_preferences');

  // Create Tag, CustomCategory, Goal, Income, RecurringIncome, and NotificationPreferences services
  final tagService = TagService(tagBox);
  final customCategoryService = CustomCategoryService(customCategoryBox);
  final goalService = GoalService(goalBox);
  final incomeService = IncomeService(incomeBox, goalService);
  final recurringIncomeService = RecurringIncomeService(recurringIncomeBox);
  final notificationPrefsService =
      NotificationPreferencesService(notificationPrefsBox);

  final smsTransactionService = SmsTransactionService(
    smsService: smsService,
    expenseService: expenseService,
    incomeService: incomeService,
  );
  await smsTransactionService.init();

  // Wire up notification service with preferences
  notificationService.setPreferencesService(notificationPrefsService);

  // Wire up services for budget notifications
  expenseService.setBudgetServices(budgetService, notificationService);

  // Wire up widget service with data services
  widgetService.setServices(
    expenseService: expenseService,
    budgetService: budgetService,
    recurringExpenseService: recurringService,
    recurringIncomeService: recurringIncomeService,
  );

  // Run the app first, then handle notifications
  runApp(LedgerifyApp(
    expenseService: expenseService,
    themeService: themeService,
    recurringService: recurringService,
    budgetService: budgetService,
    tagService: tagService,
    customCategoryService: customCategoryService,
    categoryDefaultService: categoryDefaultService,
    merchantHistoryService: merchantHistoryService,
    goalService: goalService,
    incomeService: incomeService,
    recurringIncomeService: recurringIncomeService,
    notificationService: notificationService,
    notificationPrefsService: notificationPrefsService,
    smsPermissionService: smsPermissionService,
    smsTransactionService: smsTransactionService,
    widgetService: widgetService,
  ));

  // Handle notifications, recurring items, and widget sync after first frame renders
  // This prevents blocking the initial app startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Request notification permission
    try {
      await notificationService.requestPermission();
      await notificationService.rescheduleAll();
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }

    // Generate due recurring expenses and incomes (skips if already done recently)
    try {
      await recurringService.generateDueExpensesIfNeeded(expenseService);
      await recurringIncomeService.generateDueIncomesIfNeeded(incomeService);
    } catch (e) {
      debugPrint('Error generating recurring items: $e');
    }

    // Sync home screen widget data
    try {
      final isDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      await widgetService.syncData(isDarkMode: isDark);
    } catch (e) {
      debugPrint('Error syncing widget data: $e');
    }
  });
}

/// The root widget of the Ledgerify application.
///
/// Supports light and dark themes with system preference option.
/// Philosophy: Quiet Finance — calm, premium, trustworthy.
class LedgerifyApp extends StatefulWidget {
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
  final WidgetService widgetService;

  const LedgerifyApp({
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
    required this.widgetService,
  });

  @override
  State<LedgerifyApp> createState() => _LedgerifyAppState();
}

class _LedgerifyAppState extends State<LedgerifyApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool? _lastKnownDarkMode;

  @override
  void initState() {
    super.initState();
    // Register widget callback handler for deep links
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
    // Listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync widget when app goes to background (user will see updated widget)
    if (state == AppLifecycleState.paused) {
      _syncWidgetOnBackground();
    }
  }

  /// Force sync when going to background (immediate, no debounce)
  void _syncWidgetOnBackground() {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    widget.widgetService.syncDataImmediate(isDarkMode: isDark);
  }

  /// Sync widget data only when theme changes (debounced)
  void _syncWidgetIfNeeded({bool? isDarkMode}) {
    final dark = isDarkMode ??
        (WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark);

    // Only sync if theme actually changed
    if (_lastKnownDarkMode != dark) {
      _lastKnownDarkMode = dark;
      widget.widgetService.syncData(isDarkMode: dark);
    }
  }

  /// Handle widget click deep links
  void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;

    final categoryIndex = WidgetService.parseQuickAddCallback(uri);
    if (categoryIndex != null) {
      _openAddExpense(categoryIndex >= 0 ? categoryIndex : null);
    }
  }

  /// Open AddExpenseScreen with optional pre-selected category
  void _openAddExpense(int? categoryIndex) {
    final category = categoryIndex != null &&
            categoryIndex >= 0 &&
            categoryIndex < ExpenseCategory.values.length
        ? ExpenseCategory.values[categoryIndex]
        : null;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expenseService: widget.expenseService,
          recurringService: widget.recurringService,
          tagService: widget.tagService,
          customCategoryService: widget.customCategoryService,
          categoryDefaultService: widget.categoryDefaultService,
          merchantHistoryService: widget.merchantHistoryService,
          preSelectedCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: widget.themeService.themeMode,
      builder: (context, appThemeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.themeService.useDynamicColor,
          builder: (context, useDynamicColor, _) {
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final platformBrightness = WidgetsBinding
                    .instance.platformDispatcher.platformBrightness;

                final resolvedBrightness = switch (appThemeMode) {
                  AppThemeMode.light => Brightness.light,
                  AppThemeMode.dark => Brightness.dark,
                  AppThemeMode.system => platformBrightness,
                };

                final isDark = resolvedBrightness == Brightness.dark;

                final lightTokens = useDynamicColor && lightDynamic != null
                    ? LedgerifyColorScheme.fromMaterialColorScheme(lightDynamic)
                    : LedgerifyColors.light;
                final darkTokens = useDynamicColor && darkDynamic != null
                    ? LedgerifyColorScheme.fromMaterialColorScheme(darkDynamic)
                    : LedgerifyColors.dark;

                final activeTokens = isDark ? darkTokens : lightTokens;
                final activeDynamicScheme = useDynamicColor
                    ? (isDark ? darkDynamic : lightDynamic)
                    : null;

                // Update system UI overlay based on theme
                _updateSystemUI(
                  isDark: isDark,
                  navigationBarColor:
                      activeDynamicScheme?.surface ?? activeTokens.background,
                );

                // Schedule widget sync only if theme changed (not on every build)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _syncWidgetIfNeeded(isDarkMode: isDark);
                });

                return MaterialApp(
                  navigatorKey: _navigatorKey,
                  title: 'Ledgerify',
                  debugShowCheckedModeBanner: false,

                  // Apply Ledgerify themes
                  theme: LedgerifyTheme.buildTheme(
                    tokens: lightTokens,
                    materialColorScheme: useDynamicColor ? lightDynamic : null,
                  ),
                  darkTheme: LedgerifyTheme.buildTheme(
                    tokens: darkTokens,
                    materialColorScheme: useDynamicColor ? darkDynamic : null,
                  ),
                  themeMode: appThemeMode.themeMode,

                  // Main shell with bottom navigation
                  home: MainShell(
                    expenseService: widget.expenseService,
                    themeService: widget.themeService,
                    recurringService: widget.recurringService,
                    budgetService: widget.budgetService,
                    tagService: widget.tagService,
                    customCategoryService: widget.customCategoryService,
                    categoryDefaultService: widget.categoryDefaultService,
                    merchantHistoryService: widget.merchantHistoryService,
                    goalService: widget.goalService,
                    incomeService: widget.incomeService,
                    recurringIncomeService: widget.recurringIncomeService,
                    notificationService: widget.notificationService,
                    notificationPrefsService: widget.notificationPrefsService,
                    smsPermissionService: widget.smsPermissionService,
                    smsTransactionService: widget.smsTransactionService,
                    widgetService: widget.widgetService,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUI({
    required bool isDark,
    required Color navigationBarColor,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
