import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/expense_service.dart';
import 'services/recurring_expense_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
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

  // Generate due recurring expenses on app open
  await recurringService.generateDueExpenses(expenseService);

  // Run the app
  runApp(LedgerifyApp(
    expenseService: expenseService,
    themeService: themeService,
    recurringService: recurringService,
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

  const LedgerifyApp({
    super.key,
    required this.expenseService,
    required this.themeService,
    required this.recurringService,
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

          // Home screen with services
          home: HomeScreen(
            expenseService: expenseService,
            themeService: themeService,
            recurringService: recurringService,
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
