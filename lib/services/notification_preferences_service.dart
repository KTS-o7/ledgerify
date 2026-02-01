import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_preferences.dart';

/// Service for managing notification preferences.
///
/// Stores preferences as a singleton in Hive box with key 'preferences'.
/// Provides reactive updates via ValueNotifier.
class NotificationPreferencesService {
  static const String _preferencesKey = 'preferences';

  final Box<NotificationPreferences> _box;

  /// ValueNotifier for reactive UI updates.
  final ValueNotifier<NotificationPreferences> preferences;

  NotificationPreferencesService(this._box)
      : preferences = ValueNotifier(_loadOrCreate(_box));

  /// Returns the Hive box for direct listenable access.
  Box<NotificationPreferences> get box => _box;

  /// Loads existing preferences or creates defaults.
  static NotificationPreferences _loadOrCreate(
      Box<NotificationPreferences> box) {
    final existing = box.get(_preferencesKey);
    if (existing != null) {
      return existing;
    }
    return NotificationPreferences.defaults();
  }

  /// Gets the current preferences.
  NotificationPreferences get current => preferences.value;

  /// Updates preferences and persists to storage.
  Future<void> updatePreferences(NotificationPreferences newPreferences) async {
    await _box.put(_preferencesKey, newPreferences);
    preferences.value = newPreferences;
  }

  /// Resets all preferences to defaults.
  Future<void> resetToDefaults() async {
    final defaults = NotificationPreferences.defaults();
    await updatePreferences(defaults);
  }

  // ============================================
  // Convenience Update Methods
  // ============================================

  /// Toggles master notification enable/disable.
  Future<void> setMasterEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(masterEnabled: enabled));
  }

  /// Toggles budget alerts.
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(budgetAlertsEnabled: enabled));
  }

  /// Sets the budget warning threshold (50-95).
  Future<void> setBudgetWarningThreshold(int threshold) async {
    final clamped = threshold.clamp(50, 95);
    await updatePreferences(current.copyWith(budgetWarningThreshold: clamped));
  }

  /// Adds a custom budget threshold.
  Future<void> addCustomBudgetThreshold(int threshold) async {
    if (threshold < 10 || threshold > 99) return;
    if (current.customBudgetThresholds.contains(threshold)) return;

    final newThresholds = [...current.customBudgetThresholds, threshold]
      ..sort();
    await updatePreferences(
        current.copyWith(customBudgetThresholds: newThresholds));
  }

  /// Removes a custom budget threshold.
  Future<void> removeCustomBudgetThreshold(int threshold) async {
    final newThresholds =
        current.customBudgetThresholds.where((t) => t != threshold).toList();
    await updatePreferences(
        current.copyWith(customBudgetThresholds: newThresholds));
  }

  /// Toggles recurring reminders.
  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    await updatePreferences(
        current.copyWith(recurringRemindersEnabled: enabled));
  }

  /// Sets days before recurring reminder (1-7).
  Future<void> setRecurringReminderDaysBefore(int days) async {
    final clamped = days.clamp(1, 7);
    await updatePreferences(
        current.copyWith(recurringReminderDaysBefore: clamped));
  }

  /// Toggles overdue reminders.
  Future<void> setOverdueRemindersEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(overdueRemindersEnabled: enabled));
  }

  /// Toggles goal notifications.
  Future<void> setGoalNotificationsEnabled(bool enabled) async {
    await updatePreferences(
        current.copyWith(goalNotificationsEnabled: enabled));
  }

  /// Sets goal milestone percentages.
  Future<void> setGoalMilestones(List<int> milestones) async {
    final sorted = milestones.toSet().toList()..sort();
    await updatePreferences(current.copyWith(goalMilestones: sorted));
  }

  /// Toggles a specific goal milestone.
  Future<void> toggleGoalMilestone(int milestone) async {
    final current = this.current.goalMilestones;
    List<int> newMilestones;

    if (current.contains(milestone)) {
      newMilestones = current.where((m) => m != milestone).toList();
    } else {
      newMilestones = [...current, milestone]..sort();
    }

    await updatePreferences(
        this.current.copyWith(goalMilestones: newMilestones));
  }

  /// Toggles weekly summary.
  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(weeklySummaryEnabled: enabled));
  }

  /// Sets weekly summary day (0=Sunday, 6=Saturday).
  Future<void> setWeeklySummaryDay(int day) async {
    final clamped = day.clamp(0, 6);
    await updatePreferences(current.copyWith(weeklySummaryDay: clamped));
  }

  /// Sets weekly summary time.
  Future<void> setWeeklySummaryTime(int hour, int minute) async {
    await updatePreferences(current.copyWith(
      weeklySummaryHour: hour.clamp(0, 23),
      weeklySummaryMinute: minute.clamp(0, 59),
    ));
  }

  /// Toggles daily reminder.
  Future<void> setDailyReminderEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(dailyReminderEnabled: enabled));
  }

  /// Sets daily reminder time.
  Future<void> setDailyReminderTime(int hour, int minute) async {
    await updatePreferences(current.copyWith(
      dailyReminderHour: hour.clamp(0, 23),
      dailyReminderMinute: minute.clamp(0, 59),
    ));
  }

  /// Toggles quiet hours.
  Future<void> setQuietHoursEnabled(bool enabled) async {
    await updatePreferences(current.copyWith(quietHoursEnabled: enabled));
  }

  /// Sets quiet hours start time.
  Future<void> setQuietHoursStart(int hour, int minute) async {
    await updatePreferences(current.copyWith(
      quietHoursStartHour: hour.clamp(0, 23),
      quietHoursStartMinute: minute.clamp(0, 59),
    ));
  }

  /// Sets quiet hours end time.
  Future<void> setQuietHoursEnd(int hour, int minute) async {
    await updatePreferences(current.copyWith(
      quietHoursEndHour: hour.clamp(0, 23),
      quietHoursEndMinute: minute.clamp(0, 59),
    ));
  }

  // ============================================
  // Query Methods
  // ============================================

  /// Checks if notifications are enabled (master toggle).
  bool get isEnabled => current.masterEnabled;

  /// Checks if budget alerts are enabled.
  bool get isBudgetAlertsEnabled =>
      current.masterEnabled && current.budgetAlertsEnabled;

  /// Checks if recurring reminders are enabled.
  bool get isRecurringRemindersEnabled =>
      current.masterEnabled && current.recurringRemindersEnabled;

  /// Checks if goal notifications are enabled.
  bool get isGoalNotificationsEnabled =>
      current.masterEnabled && current.goalNotificationsEnabled;

  /// Checks if weekly summary is enabled.
  bool get isWeeklySummaryEnabled =>
      current.masterEnabled && current.weeklySummaryEnabled;

  /// Checks if daily reminder is enabled.
  bool get isDailyReminderEnabled =>
      current.masterEnabled && current.dailyReminderEnabled;

  /// Checks if quiet hours are enabled.
  bool get isQuietHoursEnabled =>
      current.masterEnabled && current.quietHoursEnabled;

  /// Checks if current time is within quiet hours.
  bool isWithinQuietHours() {
    if (!isQuietHoursEnabled) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startMinutes =
        current.quietHoursStartHour * 60 + current.quietHoursStartMinute;
    final endMinutes =
        current.quietHoursEndHour * 60 + current.quietHoursEndMinute;

    // Handle overnight quiet hours (e.g., 10 PM to 8 AM)
    if (startMinutes > endMinutes) {
      // Quiet hours span midnight
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Normal range (e.g., 2 PM to 4 PM)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Checks if a notification should be sent (master enabled + not in quiet hours).
  bool shouldSendNotification() {
    return isEnabled && !isWithinQuietHours();
  }

  /// Gets the budget warning threshold.
  int get budgetWarningThreshold => current.budgetWarningThreshold;

  /// Gets all budget thresholds including custom ones.
  List<int> get allBudgetThresholds => current.allBudgetThresholds;

  /// Gets recurring reminder days before.
  int get recurringReminderDaysBefore => current.recurringReminderDaysBefore;

  /// Gets goal milestones.
  List<int> get goalMilestones => current.goalMilestones;

  /// Disposes the ValueNotifier.
  void dispose() {
    preferences.dispose();
  }
}
