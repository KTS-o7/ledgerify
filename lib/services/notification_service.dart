import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications for budget alerts.
///
/// Provides two notification channels:
/// - Budget warnings (at 80% threshold)
/// - Budget exceeded (at 100% threshold)
///
/// Uses singleton pattern to ensure single instance across the app.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification channels.
  ///
  /// Must be called before showing any notifications.
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Request notification permission (Android 13+).
  ///
  /// Returns true if permission is granted, false otherwise.
  /// On Android versions below 13, always returns true.
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
  ///
  /// Returns true if notifications are enabled, false otherwise.
  Future<bool> isPermissionGranted() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Show budget warning notification (at 80% threshold).
  ///
  /// [title] - The notification title (e.g., "Budget Warning")
  /// [body] - The notification body with details
  /// [notificationId] - Unique ID for this notification
  Future<void> showBudgetWarning({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      channelId: 'budget_warning',
      channelName: 'Budget Warnings',
      channelDesc: 'Notifications when approaching budget limit',
    );
  }

  /// Show budget exceeded notification (at 100% threshold).
  ///
  /// [title] - The notification title (e.g., "Budget Exceeded")
  /// [body] - The notification body with details
  /// [notificationId] - Unique ID for this notification
  Future<void> showBudgetExceeded({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      channelId: 'budget_exceeded',
      channelName: 'Budget Exceeded',
      channelDesc: 'Notifications when budget is exceeded',
    );
  }

  /// Internal helper to show notification.
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }

  /// Generate unique notification ID from budget ID.
  ///
  /// Uses hashCode with offset to distinguish warning vs exceeded notifications.
  /// [budgetId] - The unique budget identifier
  /// [isWarning] - If true, generates warning ID; if false, generates exceeded ID
  int getNotificationId(String budgetId, {bool isWarning = true}) {
    // Use hashCode and offset for warning vs exceeded
    return budgetId.hashCode + (isWarning ? 0 : 100000);
  }
}
