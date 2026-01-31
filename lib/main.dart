import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/expense_service.dart';
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

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: LedgerifyColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize the expense service (sets up Hive)
  final expenseService = ExpenseService();
  await expenseService.init();

  // Run the app
  runApp(LedgerifyApp(expenseService: expenseService));
}

/// The root widget of the Ledgerify application.
///
/// Uses the Ledgerify Design Language - dark theme only.
/// Philosophy: Quiet Finance — calm, premium, trustworthy.
class LedgerifyApp extends StatelessWidget {
  final ExpenseService expenseService;

  const LedgerifyApp({super.key, required this.expenseService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledgerify',
      debugShowCheckedModeBanner: false,

      // Apply Ledgerify dark theme - the only theme
      theme: LedgerifyTheme.darkTheme,
      darkTheme: LedgerifyTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Home screen is the initial route
      home: HomeScreen(expenseService: expenseService),
    );
  }
}
