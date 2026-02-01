import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/recurring_income.dart';
import '../utils/currency_formatter.dart';
import 'notification_preferences_service.dart';

/// Service for managing local notifications.
///
/// Notification channels:
/// - Budget warnings (approaching limit)
/// - Budget exceeded (over limit)
/// - Recurring reminders (upcoming expenses/income)
/// - Goal progress (milestones and completion)
/// - Weekly summary (spending overview)
/// - Daily reminder (add expenses)
///
/// Uses singleton pattern to ensure single instance across the app.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationPreferencesService? _preferencesService;

  // Notification ID ranges for different types
  static const int _budgetWarningBase = 0;
  static const int _budgetExceededBase = 100000;
  static const int _budgetCustomBase = 200000;
  static const int _recurringExpenseBase = 300000;
  static const int _recurringIncomeBase = 400000;
  static const int _goalMilestoneBase = 500000;
  static const int _goalCompletedBase = 600000;
  static const int _weeklySummaryId = 700000;
  static const int _dailyReminderId = 700001;

  // ============================================
  // Initialization
  // ============================================

  /// Initialize notification channels and timezone.
  ///
  /// Must be called before showing any notifications.
  Future<void> init() async {
    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Sets the preferences service for checking user settings.
  void setPreferencesService(NotificationPreferencesService service) {
    _preferencesService = service;
  }

  /// Request notification permission (Android 13+).
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Check if notifications are permitted.
  Future<bool> isPermissionGranted() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  // ============================================
  // Permission & Preference Checks
  // ============================================

  /// Checks if notifications should be sent based on preferences.
  bool _shouldSend() {
    if (_preferencesService == null) return true;
    return _preferencesService!.shouldSendNotification();
  }

  /// Checks if budget alerts are enabled.
  bool _isBudgetAlertsEnabled() {
    if (_preferencesService == null) return true;
    return _preferencesService!.isBudgetAlertsEnabled;
  }

  /// Checks if recurring reminders are enabled.
  bool _isRecurringRemindersEnabled() {
    if (_preferencesService == null) return true;
    return _preferencesService!.isRecurringRemindersEnabled;
  }

  /// Checks if goal notifications are enabled.
  bool _isGoalNotificationsEnabled() {
    if (_preferencesService == null) return true;
    return _preferencesService!.isGoalNotificationsEnabled;
  }

  // ============================================
  // Budget Notifications
  // ============================================

  /// Show budget warning notification (at custom threshold).
  Future<void> showBudgetWarning({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    if (!_shouldSend() || !_isBudgetAlertsEnabled()) return;

    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      channelId: 'budget_warning',
      channelName: 'Budget Warnings',
      channelDesc: 'Notifications when approaching budget limit',
    );
  }

  /// Show budget exceeded notification (at 100%).
  Future<void> showBudgetExceeded({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    if (!_shouldSend() || !_isBudgetAlertsEnabled()) return;

    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      channelId: 'budget_exceeded',
      channelName: 'Budget Exceeded',
      channelDesc: 'Notifications when budget is exceeded',
    );
  }

  /// Show custom budget threshold notification.
  Future<void> showBudgetCustomThreshold({
    required String title,
    required String body,
    required String budgetId,
    required int threshold,
  }) async {
    if (!_shouldSend() || !_isBudgetAlertsEnabled()) return;

    final notificationId = _budgetCustomBase + budgetId.hashCode + threshold;

    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      channelId: 'budget_warning',
      channelName: 'Budget Warnings',
      channelDesc: 'Notifications when approaching budget limit',
    );
  }

  // ============================================
  // Recurring Expense/Income Notifications
  // ============================================

  /// Show reminder for upcoming recurring expense.
  Future<void> showRecurringExpenseReminder({
    required RecurringExpense expense,
    required int daysUntil,
  }) async {
    if (!_shouldSend() || !_isRecurringRemindersEnabled()) return;

    final amount = CurrencyFormatter.format(expense.amount);
    final dayText = daysUntil == 1 ? 'tomorrow' : 'in $daysUntil days';

    await _showNotification(
      id: _recurringExpenseBase + expense.id.hashCode,
      title: 'Upcoming Expense',
      body: '${expense.category.displayName} expense of $amount due $dayText',
      channelId: 'recurring_reminder',
      channelName: 'Recurring Reminders',
      channelDesc: 'Reminders for upcoming recurring expenses and income',
    );
  }

  /// Show reminder for upcoming recurring income.
  Future<void> showRecurringIncomeReminder({
    required RecurringIncome income,
    required int daysUntil,
  }) async {
    if (!_shouldSend() || !_isRecurringRemindersEnabled()) return;

    final amount = CurrencyFormatter.format(income.amount);
    final dayText = daysUntil == 1 ? 'tomorrow' : 'in $daysUntil days';

    await _showNotification(
      id: _recurringIncomeBase + income.id.hashCode,
      title: 'Upcoming Income',
      body: '${income.source.displayName} income of $amount expected $dayText',
      channelId: 'recurring_reminder',
      channelName: 'Recurring Reminders',
      channelDesc: 'Reminders for upcoming recurring expenses and income',
    );
  }

  /// Show reminder for overdue recurring expense.
  Future<void> showOverdueExpenseReminder({
    required RecurringExpense expense,
    required int daysOverdue,
  }) async {
    if (!_shouldSend() || !_isRecurringRemindersEnabled()) return;
    if (_preferencesService != null &&
        !_preferencesService!.current.overdueRemindersEnabled) {
      return;
    }

    final amount = CurrencyFormatter.format(expense.amount);
    final dayText = daysOverdue == 1 ? '1 day' : '$daysOverdue days';

    await _showNotification(
      id: _recurringExpenseBase + expense.id.hashCode + 50000,
      title: 'Overdue Expense',
      body:
          '${expense.category.displayName} expense of $amount is $dayText overdue',
      channelId: 'recurring_reminder',
      channelName: 'Recurring Reminders',
      channelDesc: 'Reminders for upcoming recurring expenses and income',
    );
  }

  // ============================================
  // Goal Notifications
  // ============================================

  /// Show goal milestone notification.
  Future<void> showGoalMilestone({
    required Goal goal,
    required int milestone,
  }) async {
    if (!_shouldSend() || !_isGoalNotificationsEnabled()) return;

    // Check if this milestone is enabled in preferences
    if (_preferencesService != null &&
        !_preferencesService!.goalMilestones.contains(milestone)) {
      return;
    }

    final amount = CurrencyFormatter.format(goal.currentAmount);

    await _showNotification(
      id: _goalMilestoneBase + goal.id.hashCode + milestone,
      title: 'Goal Progress',
      body: '${goal.name} is $milestone% complete. Saved $amount so far.',
      channelId: 'goal_progress',
      channelName: 'Goal Progress',
      channelDesc: 'Notifications for goal milestones and completions',
    );
  }

  /// Show goal completed notification.
  Future<void> showGoalCompleted({required Goal goal}) async {
    if (!_shouldSend() || !_isGoalNotificationsEnabled()) return;

    final amount = CurrencyFormatter.format(goal.targetAmount);

    await _showNotification(
      id: _goalCompletedBase + goal.id.hashCode,
      title: 'Goal Achieved',
      body:
          'Congratulations! You\'ve reached your ${goal.name} goal of $amount',
      channelId: 'goal_progress',
      channelName: 'Goal Progress',
      channelDesc: 'Notifications for goal milestones and completions',
    );
  }

  // ============================================
  // Scheduled Notifications
  // ============================================

  /// Show weekly summary notification.
  Future<void> showWeeklySummary({
    required double totalIncome,
    required double totalExpenses,
    required double netSavings,
  }) async {
    if (!_shouldSend()) return;
    if (_preferencesService != null &&
        !_preferencesService!.isWeeklySummaryEnabled) {
      return;
    }

    final incomeStr = CurrencyFormatter.format(totalIncome);
    final expenseStr = CurrencyFormatter.format(totalExpenses);
    final sign = netSavings >= 0 ? '+' : '';
    final savingsStr = '$sign${CurrencyFormatter.format(netSavings)}';

    await _showNotification(
      id: _weeklySummaryId,
      title: 'Weekly Summary',
      body: 'Income: $incomeStr | Expenses: $expenseStr | Net: $savingsStr',
      channelId: 'weekly_summary',
      channelName: 'Weekly Summary',
      channelDesc: 'Weekly spending and savings summaries',
    );
  }

  /// Show daily reminder notification.
  Future<void> showDailyReminder() async {
    if (!_shouldSend()) return;
    if (_preferencesService != null &&
        !_preferencesService!.isDailyReminderEnabled) {
      return;
    }

    await _showNotification(
      id: _dailyReminderId,
      title: 'Daily Reminder',
      body: 'Have you logged your expenses today?',
      channelId: 'daily_reminder',
      channelName: 'Daily Reminder',
      channelDesc: 'Daily reminders to track expenses',
    );
  }

  /// Schedule the weekly summary notification.
  Future<void> scheduleWeeklySummary() async {
    if (_preferencesService == null ||
        !_preferencesService!.isWeeklySummaryEnabled) {
      await cancelWeeklySummary();
      return;
    }

    final prefs = _preferencesService!.current;
    final nextSchedule = _getNextWeeklySchedule(
      prefs.weeklySummaryDay,
      prefs.weeklySummaryHour,
      prefs.weeklySummaryMinute,
    );

    const androidDetails = AndroidNotificationDetails(
      'weekly_summary',
      'Weekly Summary',
      channelDescription: 'Weekly spending and savings summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.zonedSchedule(
      _weeklySummaryId,
      'Weekly Summary',
      'Tap to view your weekly spending summary',
      nextSchedule,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedule the daily reminder notification.
  Future<void> scheduleDailyReminder() async {
    if (_preferencesService == null ||
        !_preferencesService!.isDailyReminderEnabled) {
      await cancelDailyReminder();
      return;
    }

    final prefs = _preferencesService!.current;
    final nextSchedule = _getNextDailySchedule(
      prefs.dailyReminderHour,
      prefs.dailyReminderMinute,
    );

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Daily reminders to track expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.zonedSchedule(
      _dailyReminderId,
      'Daily Reminder',
      'Have you logged your expenses today?',
      nextSchedule,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel weekly summary scheduled notification.
  Future<void> cancelWeeklySummary() async {
    await _notifications.cancel(_weeklySummaryId);
  }

  /// Cancel daily reminder scheduled notification.
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAllScheduled() async {
    await cancelWeeklySummary();
    await cancelDailyReminder();
  }

  /// Reschedule all enabled notifications.
  Future<void> rescheduleAll() async {
    await scheduleWeeklySummary();
    await scheduleDailyReminder();
  }

  // ============================================
  // Helper Methods
  // ============================================

  /// Internal helper to show notification.
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
    );
    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }

  /// Calculate next weekly schedule time.
  tz.TZDateTime _getNextWeeklySchedule(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Find the next occurrence of the specified day
    while (scheduled.weekday != dayOfWeek + 1 || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Calculate next daily schedule time.
  tz.TZDateTime _getNextDailySchedule(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Generate unique notification ID from budget ID.
  int getNotificationId(String budgetId, {bool isWarning = true}) {
    return budgetId.hashCode +
        (isWarning ? _budgetWarningBase : _budgetExceededBase);
  }

  /// Generate notification ID for custom threshold.
  int getCustomThresholdNotificationId(String budgetId, int threshold) {
    return _budgetCustomBase + budgetId.hashCode + threshold;
  }
}
