import 'package:hive/hive.dart';

part 'notification_preferences.g.dart';

/// Model representing user notification preferences.
///
/// Stored as a singleton in Hive with key 'preferences'.
/// Controls all notification behavior in the app.
///
/// Hive Type IDs used:
/// - 13: NotificationPreferences
/// - 14: TimeOfDayAdapter (custom adapter for storing time)
@HiveType(typeId: 13)
class NotificationPreferences extends HiveObject {
  // ============================================
  // Master Toggle
  // ============================================

  /// Global notification enable/disable toggle.
  /// When false, no notifications are sent.
  @HiveField(0)
  final bool masterEnabled;

  // ============================================
  // Budget Alerts
  // ============================================

  /// Enable budget warning and exceeded notifications.
  @HiveField(1)
  final bool budgetAlertsEnabled;

  /// Warning threshold percentage (default 80).
  /// Notification sent when spending reaches this % of budget.
  @HiveField(2)
  final int budgetWarningThreshold;

  /// Additional custom thresholds for budget alerts.
  /// E.g., [50, 75, 90] for extra warnings.
  @HiveField(3)
  final List<int> customBudgetThresholds;

  // ============================================
  // Recurring Reminders
  // ============================================

  /// Enable reminders for upcoming recurring expenses/income.
  @HiveField(4)
  final bool recurringRemindersEnabled;

  /// Days before due date to send reminder (1-7).
  @HiveField(5)
  final int recurringReminderDaysBefore;

  /// Enable reminders for overdue recurring items.
  @HiveField(6)
  final bool overdueRemindersEnabled;

  // ============================================
  // Goal Notifications
  // ============================================

  /// Enable goal progress and completion notifications.
  @HiveField(7)
  final bool goalNotificationsEnabled;

  /// Milestone percentages to notify at.
  /// Default: [25, 50, 75, 100]
  @HiveField(8)
  final List<int> goalMilestones;

  // ============================================
  // Scheduled Notifications
  // ============================================

  /// Enable weekly spending/savings summary.
  @HiveField(9)
  final bool weeklySummaryEnabled;

  /// Day of week for weekly summary (0=Sunday, 6=Saturday).
  @HiveField(10)
  final int weeklySummaryDay;

  /// Hour for weekly summary (0-23).
  @HiveField(11)
  final int weeklySummaryHour;

  /// Minute for weekly summary (0-59).
  @HiveField(12)
  final int weeklySummaryMinute;

  /// Enable daily reminder to add expenses.
  @HiveField(13)
  final bool dailyReminderEnabled;

  /// Hour for daily reminder (0-23).
  @HiveField(14)
  final int dailyReminderHour;

  /// Minute for daily reminder (0-59).
  @HiveField(15)
  final int dailyReminderMinute;

  // ============================================
  // Quiet Hours
  // ============================================

  /// Enable quiet hours (no notifications during this period).
  @HiveField(16)
  final bool quietHoursEnabled;

  /// Quiet hours start hour (0-23).
  @HiveField(17)
  final int quietHoursStartHour;

  /// Quiet hours start minute (0-59).
  @HiveField(18)
  final int quietHoursStartMinute;

  /// Quiet hours end hour (0-23).
  @HiveField(19)
  final int quietHoursEndHour;

  /// Quiet hours end minute (0-59).
  @HiveField(20)
  final int quietHoursEndMinute;

  // ============================================
  // Constructor
  // ============================================

  NotificationPreferences({
    this.masterEnabled = true,
    // Budget
    this.budgetAlertsEnabled = true,
    this.budgetWarningThreshold = 80,
    List<int>? customBudgetThresholds,
    // Recurring
    this.recurringRemindersEnabled = true,
    this.recurringReminderDaysBefore = 1,
    this.overdueRemindersEnabled = true,
    // Goals
    this.goalNotificationsEnabled = true,
    List<int>? goalMilestones,
    // Weekly summary
    this.weeklySummaryEnabled = false,
    this.weeklySummaryDay = 0, // Sunday
    this.weeklySummaryHour = 18, // 6 PM
    this.weeklySummaryMinute = 0,
    // Daily reminder
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20, // 8 PM
    this.dailyReminderMinute = 0,
    // Quiet hours
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22, // 10 PM
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8, // 8 AM
    this.quietHoursEndMinute = 0,
  })  : customBudgetThresholds = customBudgetThresholds ?? [],
        goalMilestones = goalMilestones ?? [25, 50, 75, 100];

  // ============================================
  // Factory: Default preferences
  // ============================================

  /// Creates default notification preferences.
  factory NotificationPreferences.defaults() {
    return NotificationPreferences();
  }

  // ============================================
  // Convenience Getters
  // ============================================

  /// Returns all budget thresholds in sorted order.
  /// Includes warning threshold and any custom thresholds.
  List<int> get allBudgetThresholds {
    final thresholds = <int>{budgetWarningThreshold, ...customBudgetThresholds};
    final sorted = thresholds.toList()..sort();
    return sorted;
  }

  /// Checks if a specific budget threshold is enabled.
  bool isBudgetThresholdEnabled(int threshold) {
    if (threshold == 100) return true; // Exceeded always enabled
    if (threshold == budgetWarningThreshold) return true;
    return customBudgetThresholds.contains(threshold);
  }

  /// Weekly summary time as formatted string (e.g., "6:00 PM").
  String get weeklySummaryTimeFormatted {
    return _formatTime(weeklySummaryHour, weeklySummaryMinute);
  }

  /// Daily reminder time as formatted string.
  String get dailyReminderTimeFormatted {
    return _formatTime(dailyReminderHour, dailyReminderMinute);
  }

  /// Quiet hours start time as formatted string.
  String get quietHoursStartFormatted {
    return _formatTime(quietHoursStartHour, quietHoursStartMinute);
  }

  /// Quiet hours end time as formatted string.
  String get quietHoursEndFormatted {
    return _formatTime(quietHoursEndHour, quietHoursEndMinute);
  }

  /// Weekly summary day name.
  String get weeklySummaryDayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[weeklySummaryDay];
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // ============================================
  // Copy With
  // ============================================

  NotificationPreferences copyWith({
    bool? masterEnabled,
    // Budget
    bool? budgetAlertsEnabled,
    int? budgetWarningThreshold,
    List<int>? customBudgetThresholds,
    // Recurring
    bool? recurringRemindersEnabled,
    int? recurringReminderDaysBefore,
    bool? overdueRemindersEnabled,
    // Goals
    bool? goalNotificationsEnabled,
    List<int>? goalMilestones,
    // Weekly summary
    bool? weeklySummaryEnabled,
    int? weeklySummaryDay,
    int? weeklySummaryHour,
    int? weeklySummaryMinute,
    // Daily reminder
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    // Quiet hours
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      // Budget
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      budgetWarningThreshold:
          budgetWarningThreshold ?? this.budgetWarningThreshold,
      customBudgetThresholds:
          customBudgetThresholds ?? this.customBudgetThresholds,
      // Recurring
      recurringRemindersEnabled:
          recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      recurringReminderDaysBefore:
          recurringReminderDaysBefore ?? this.recurringReminderDaysBefore,
      overdueRemindersEnabled:
          overdueRemindersEnabled ?? this.overdueRemindersEnabled,
      // Goals
      goalNotificationsEnabled:
          goalNotificationsEnabled ?? this.goalNotificationsEnabled,
      goalMilestones: goalMilestones ?? this.goalMilestones,
      // Weekly summary
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      weeklySummaryDay: weeklySummaryDay ?? this.weeklySummaryDay,
      weeklySummaryHour: weeklySummaryHour ?? this.weeklySummaryHour,
      weeklySummaryMinute: weeklySummaryMinute ?? this.weeklySummaryMinute,
      // Daily reminder
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      // Quiet hours
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    );
  }

  // ============================================
  // Serialization
  // ============================================

  Map<String, dynamic> toJson() {
    return {
      'masterEnabled': masterEnabled,
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'budgetWarningThreshold': budgetWarningThreshold,
      'customBudgetThresholds': customBudgetThresholds,
      'recurringRemindersEnabled': recurringRemindersEnabled,
      'recurringReminderDaysBefore': recurringReminderDaysBefore,
      'overdueRemindersEnabled': overdueRemindersEnabled,
      'goalNotificationsEnabled': goalNotificationsEnabled,
      'goalMilestones': goalMilestones,
      'weeklySummaryEnabled': weeklySummaryEnabled,
      'weeklySummaryDay': weeklySummaryDay,
      'weeklySummaryHour': weeklySummaryHour,
      'weeklySummaryMinute': weeklySummaryMinute,
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderHour': dailyReminderHour,
      'dailyReminderMinute': dailyReminderMinute,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStartHour': quietHoursStartHour,
      'quietHoursStartMinute': quietHoursStartMinute,
      'quietHoursEndHour': quietHoursEndHour,
      'quietHoursEndMinute': quietHoursEndMinute,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      budgetAlertsEnabled: json['budgetAlertsEnabled'] as bool? ?? true,
      budgetWarningThreshold: json['budgetWarningThreshold'] as int? ?? 80,
      customBudgetThresholds:
          (json['customBudgetThresholds'] as List<dynamic>?)?.cast<int>() ?? [],
      recurringRemindersEnabled:
          json['recurringRemindersEnabled'] as bool? ?? true,
      recurringReminderDaysBefore:
          json['recurringReminderDaysBefore'] as int? ?? 1,
      overdueRemindersEnabled: json['overdueRemindersEnabled'] as bool? ?? true,
      goalNotificationsEnabled:
          json['goalNotificationsEnabled'] as bool? ?? true,
      goalMilestones: (json['goalMilestones'] as List<dynamic>?)?.cast<int>() ??
          [25, 50, 75, 100],
      weeklySummaryEnabled: json['weeklySummaryEnabled'] as bool? ?? false,
      weeklySummaryDay: json['weeklySummaryDay'] as int? ?? 0,
      weeklySummaryHour: json['weeklySummaryHour'] as int? ?? 18,
      weeklySummaryMinute: json['weeklySummaryMinute'] as int? ?? 0,
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
      dailyReminderHour: json['dailyReminderHour'] as int? ?? 20,
      dailyReminderMinute: json['dailyReminderMinute'] as int? ?? 0,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStartHour: json['quietHoursStartHour'] as int? ?? 22,
      quietHoursStartMinute: json['quietHoursStartMinute'] as int? ?? 0,
      quietHoursEndHour: json['quietHoursEndHour'] as int? ?? 8,
      quietHoursEndMinute: json['quietHoursEndMinute'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(masterEnabled: $masterEnabled, '
        'budgetAlerts: $budgetAlertsEnabled, recurring: $recurringRemindersEnabled, '
        'goals: $goalNotificationsEnabled)';
  }
}
