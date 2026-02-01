import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';
import '../theme/ledgerify_theme.dart';

/// Notification Settings Screen - Ledgerify Design Language
///
/// Allows users to configure all notification preferences:
/// - Master toggle
/// - Budget alerts with custom thresholds
/// - Recurring expense/income reminders
/// - Goal progress notifications
/// - Weekly summary scheduling
/// - Daily reminder scheduling
/// - Quiet hours
class NotificationSettingsScreen extends StatelessWidget {
  final NotificationPreferencesService preferencesService;
  final NotificationService notificationService;

  const NotificationSettingsScreen({
    super.key,
    required this.preferencesService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: colors.textPrimary,
        ),
        title: Text(
          'Notifications',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: ValueListenableBuilder<NotificationPreferences>(
        valueListenable: preferencesService.preferences,
        builder: (context, prefs, _) {
          return ListView(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            children: [
              // Master Toggle
              _MasterToggleCard(
                enabled: prefs.masterEnabled,
                onChanged: (value) =>
                    preferencesService.setMasterEnabled(value),
                colors: colors,
              ),

              if (prefs.masterEnabled) ...[
                LedgerifySpacing.verticalXl,

                // Budget Alerts Section
                _SectionHeader(title: 'Budget Alerts', colors: colors),
                LedgerifySpacing.verticalSm,
                _BudgetAlertsCard(
                  prefs: prefs,
                  preferencesService: preferencesService,
                  colors: colors,
                ),

                LedgerifySpacing.verticalXl,

                // Recurring Reminders Section
                _SectionHeader(title: 'Recurring Reminders', colors: colors),
                LedgerifySpacing.verticalSm,
                _RecurringRemindersCard(
                  prefs: prefs,
                  preferencesService: preferencesService,
                  colors: colors,
                ),

                LedgerifySpacing.verticalXl,

                // Goal Notifications Section
                _SectionHeader(title: 'Goal Notifications', colors: colors),
                LedgerifySpacing.verticalSm,
                _GoalNotificationsCard(
                  prefs: prefs,
                  preferencesService: preferencesService,
                  colors: colors,
                ),

                LedgerifySpacing.verticalXl,

                // Scheduled Notifications Section
                _SectionHeader(
                    title: 'Scheduled Notifications', colors: colors),
                LedgerifySpacing.verticalSm,
                _ScheduledNotificationsCard(
                  prefs: prefs,
                  preferencesService: preferencesService,
                  notificationService: notificationService,
                  colors: colors,
                ),

                LedgerifySpacing.verticalXl,

                // Quiet Hours Section
                _SectionHeader(title: 'Quiet Hours', colors: colors),
                LedgerifySpacing.verticalSm,
                _QuietHoursCard(
                  prefs: prefs,
                  preferencesService: preferencesService,
                  colors: colors,
                ),

                LedgerifySpacing.verticalXl,

                // Reset to Defaults
                _ResetButton(
                  onPressed: () => _showResetConfirmation(context),
                  colors: colors,
                ),
              ],

              LedgerifySpacing.verticalXl,
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Reset Notifications?',
          style: LedgerifyTypography.headlineSmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will reset all notification settings to their defaults.',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              preferencesService.resetToDefaults();
              Navigator.pop(context);
            },
            child: Text(
              'Reset',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.negative,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Section Header
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final LedgerifyColorScheme colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: LedgerifySpacing.xs),
      child: Text(
        title,
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.textTertiary,
        ),
      ),
    );
  }
}

// ============================================
// Master Toggle Card
// ============================================

class _MasterToggleCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final LedgerifyColorScheme colors;

  const _MasterToggleCard({
    required this.enabled,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(LedgerifySpacing.sm),
            decoration: BoxDecoration(
              color: enabled ? colors.accentMuted : colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: enabled ? colors.accent : colors.textTertiary,
              size: 24,
            ),
          ),
          LedgerifySpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Notifications',
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                LedgerifySpacing.verticalXs,
                Text(
                  enabled
                      ? 'Notifications are enabled'
                      : 'All notifications are disabled',
                  style: LedgerifyTypography.labelSmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: colors.accent,
            activeTrackColor: colors.accentMuted,
            inactiveThumbColor: colors.textTertiary,
            inactiveTrackColor: colors.surfaceHighlight,
          ),
        ],
      ),
    );
  }
}

// ============================================
// Budget Alerts Card
// ============================================

class _BudgetAlertsCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final LedgerifyColorScheme colors;

  const _BudgetAlertsCard({
    required this.prefs,
    required this.preferencesService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Enable toggle
          _SettingsTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Budget Alerts',
            subtitle: 'Notify when approaching budget limits',
            trailing: Switch(
              value: prefs.budgetAlertsEnabled,
              onChanged: preferencesService.setBudgetAlertsEnabled,
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            colors: colors,
          ),

          if (prefs.budgetAlertsEnabled) ...[
            _Divider(colors: colors),

            // Warning threshold slider
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Warning Threshold',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${prefs.budgetWarningThreshold}%',
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  LedgerifySpacing.verticalSm,
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.surfaceHighlight,
                      thumbColor: colors.accent,
                      overlayColor: colors.accentMuted,
                    ),
                    child: Slider(
                      value: prefs.budgetWarningThreshold.toDouble(),
                      min: 50,
                      max: 95,
                      divisions: 9,
                      onChanged: (value) {
                        preferencesService
                            .setBudgetWarningThreshold(value.toInt());
                      },
                    ),
                  ),
                  Text(
                    'Notifies when spending reaches this percentage',
                    style: LedgerifyTypography.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            _Divider(colors: colors),

            // Custom thresholds
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Custom Thresholds',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: colors.accent,
                        ),
                        onPressed: () => _showAddThresholdDialog(context),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  if (prefs.customBudgetThresholds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: LedgerifySpacing.sm),
                      child: Text(
                        'No custom thresholds added',
                        style: LedgerifyTypography.labelSmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: LedgerifySpacing.sm),
                      child: Wrap(
                        spacing: LedgerifySpacing.sm,
                        runSpacing: LedgerifySpacing.sm,
                        children: prefs.customBudgetThresholds.map((threshold) {
                          return Chip(
                            label: Text('$threshold%'),
                            labelStyle: LedgerifyTypography.labelSmall.copyWith(
                              color: colors.textPrimary,
                            ),
                            backgroundColor: colors.surfaceHighlight,
                            deleteIcon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colors.textTertiary,
                            ),
                            onDeleted: () {
                              preferencesService
                                  .removeCustomBudgetThreshold(threshold);
                            },
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: LedgerifyRadius.borderRadiusSm,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddThresholdDialog(BuildContext context) {
    int selectedThreshold = 50;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: colors.surfaceElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: LedgerifyRadius.borderRadiusLg,
            ),
            title: Text(
              'Add Threshold',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedThreshold%',
                  style: LedgerifyTypography.amountLarge.copyWith(
                    color: colors.accent,
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.surfaceHighlight,
                    thumbColor: colors.accent,
                    overlayColor: colors.accentMuted,
                  ),
                  child: Slider(
                    value: selectedThreshold.toDouble(),
                    min: 10,
                    max: 99,
                    divisions: 89,
                    onChanged: (value) {
                      setState(() => selectedThreshold = value.toInt());
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  preferencesService
                      .addCustomBudgetThreshold(selectedThreshold);
                  Navigator.pop(context);
                },
                child: Text(
                  'Add',
                  style: LedgerifyTypography.labelMedium.copyWith(
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================
// Recurring Reminders Card
// ============================================

class _RecurringRemindersCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final LedgerifyColorScheme colors;

  const _RecurringRemindersCard({
    required this.prefs,
    required this.preferencesService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Enable toggle
          _SettingsTile(
            icon: Icons.repeat_rounded,
            title: 'Recurring Reminders',
            subtitle: 'Remind about upcoming expenses and income',
            trailing: Switch(
              value: prefs.recurringRemindersEnabled,
              onChanged: preferencesService.setRecurringRemindersEnabled,
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            colors: colors,
          ),

          if (prefs.recurringRemindersEnabled) ...[
            _Divider(colors: colors),

            // Days before reminder
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remind Days Before',
                        style: LedgerifyTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${prefs.recurringReminderDaysBefore} day${prefs.recurringReminderDaysBefore > 1 ? 's' : ''}',
                        style: LedgerifyTypography.labelMedium.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  LedgerifySpacing.verticalSm,
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.surfaceHighlight,
                      thumbColor: colors.accent,
                      overlayColor: colors.accentMuted,
                    ),
                    child: Slider(
                      value: prefs.recurringReminderDaysBefore.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      onChanged: (value) {
                        preferencesService
                            .setRecurringReminderDaysBefore(value.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),

            _Divider(colors: colors),

            // Overdue reminders toggle
            _SettingsTile(
              icon: Icons.warning_amber_rounded,
              title: 'Overdue Reminders',
              subtitle: 'Notify about overdue recurring items',
              trailing: Switch(
                value: prefs.overdueRemindersEnabled,
                onChanged: preferencesService.setOverdueRemindersEnabled,
                activeColor: colors.accent,
                activeTrackColor: colors.accentMuted,
                inactiveThumbColor: colors.textTertiary,
                inactiveTrackColor: colors.surfaceHighlight,
              ),
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// Goal Notifications Card
// ============================================

class _GoalNotificationsCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final LedgerifyColorScheme colors;

  const _GoalNotificationsCard({
    required this.prefs,
    required this.preferencesService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Enable toggle
          _SettingsTile(
            icon: Icons.flag_rounded,
            title: 'Goal Notifications',
            subtitle: 'Celebrate milestones and completions',
            trailing: Switch(
              value: prefs.goalNotificationsEnabled,
              onChanged: preferencesService.setGoalNotificationsEnabled,
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            colors: colors,
          ),

          if (prefs.goalNotificationsEnabled) ...[
            _Divider(colors: colors),

            // Milestone checkboxes
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notify at Milestones',
                    style: LedgerifyTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  LedgerifySpacing.verticalMd,
                  Wrap(
                    spacing: LedgerifySpacing.md,
                    runSpacing: LedgerifySpacing.sm,
                    children: [25, 50, 75, 100].map((milestone) {
                      final isSelected =
                          prefs.goalMilestones.contains(milestone);
                      return FilterChip(
                        label: Text('$milestone%'),
                        labelStyle: LedgerifyTypography.labelSmall.copyWith(
                          color:
                              isSelected ? colors.accent : colors.textSecondary,
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          preferencesService.toggleGoalMilestone(milestone);
                        },
                        backgroundColor: colors.surfaceHighlight,
                        selectedColor: colors.accentMuted,
                        checkmarkColor: colors.accent,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: LedgerifyRadius.borderRadiusSm,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// Scheduled Notifications Card
// ============================================

class _ScheduledNotificationsCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final NotificationService notificationService;
  final LedgerifyColorScheme colors;

  const _ScheduledNotificationsCard({
    required this.prefs,
    required this.preferencesService,
    required this.notificationService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Weekly Summary
          _SettingsTile(
            icon: Icons.calendar_view_week_rounded,
            title: 'Weekly Summary',
            subtitle: prefs.weeklySummaryEnabled
                ? '${prefs.weeklySummaryDayName} at ${prefs.weeklySummaryTimeFormatted}'
                : 'Disabled',
            trailing: Switch(
              value: prefs.weeklySummaryEnabled,
              onChanged: (value) async {
                await preferencesService.setWeeklySummaryEnabled(value);
                await notificationService.scheduleWeeklySummary();
              },
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            onTap: prefs.weeklySummaryEnabled
                ? () => _showWeeklySummarySettings(context)
                : null,
            colors: colors,
          ),

          _Divider(colors: colors),

          // Daily Reminder
          _SettingsTile(
            icon: Icons.today_rounded,
            title: 'Daily Reminder',
            subtitle: prefs.dailyReminderEnabled
                ? 'Daily at ${prefs.dailyReminderTimeFormatted}'
                : 'Disabled',
            trailing: Switch(
              value: prefs.dailyReminderEnabled,
              onChanged: (value) async {
                await preferencesService.setDailyReminderEnabled(value);
                await notificationService.scheduleDailyReminder();
              },
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            onTap: prefs.dailyReminderEnabled
                ? () => _showDailyReminderSettings(context)
                : null,
            colors: colors,
          ),
        ],
      ),
    );
  }

  void _showWeeklySummarySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: LedgerifyRadius.borderRadiusTopXl,
      ),
      builder: (context) => _WeeklySummarySheet(
        prefs: prefs,
        preferencesService: preferencesService,
        notificationService: notificationService,
        colors: colors,
      ),
    );
  }

  void _showDailyReminderSettings(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: prefs.dailyReminderHour,
        minute: prefs.dailyReminderMinute,
      ),
    );

    if (time != null) {
      await preferencesService.setDailyReminderTime(time.hour, time.minute);
      await notificationService.scheduleDailyReminder();
    }
  }
}

// ============================================
// Weekly Summary Sheet
// ============================================

class _WeeklySummarySheet extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final NotificationService notificationService;
  final LedgerifyColorScheme colors;

  const _WeeklySummarySheet({
    required this.prefs,
    required this.preferencesService,
    required this.notificationService,
    required this.colors,
  });

  static const _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            LedgerifySpacing.verticalLg,

            Text(
              'Weekly Summary',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalLg,

            // Day selection
            Text(
              'Day',
              style: LedgerifyTypography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Wrap(
              spacing: LedgerifySpacing.sm,
              runSpacing: LedgerifySpacing.sm,
              children: List.generate(7, (index) {
                final isSelected = prefs.weeklySummaryDay == index;
                return ChoiceChip(
                  label: Text(_days[index].substring(0, 3)),
                  labelStyle: LedgerifyTypography.labelSmall.copyWith(
                    color: isSelected ? colors.accent : colors.textSecondary,
                  ),
                  selected: isSelected,
                  onSelected: (_) async {
                    await preferencesService.setWeeklySummaryDay(index);
                    await notificationService.scheduleWeeklySummary();
                  },
                  backgroundColor: colors.surfaceHighlight,
                  selectedColor: colors.accentMuted,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusSm,
                  ),
                );
              }),
            ),

            LedgerifySpacing.verticalLg,

            // Time selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Time',
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: prefs.weeklySummaryHour,
                      minute: prefs.weeklySummaryMinute,
                    ),
                  );

                  if (time != null) {
                    await preferencesService.setWeeklySummaryTime(
                      time.hour,
                      time.minute,
                    );
                    await notificationService.scheduleWeeklySummary();
                  }
                },
                child: Text(
                  prefs.weeklySummaryTimeFormatted,
                  style: LedgerifyTypography.bodyLarge.copyWith(
                    color: colors.accent,
                  ),
                ),
              ),
            ),

            LedgerifySpacing.verticalLg,
          ],
        ),
      ),
    );
  }
}

// ============================================
// Quiet Hours Card
// ============================================

class _QuietHoursCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final NotificationPreferencesService preferencesService;
  final LedgerifyColorScheme colors;

  const _QuietHoursCard({
    required this.prefs,
    required this.preferencesService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          // Enable toggle
          _SettingsTile(
            icon: Icons.do_not_disturb_on_rounded,
            title: 'Quiet Hours',
            subtitle: prefs.quietHoursEnabled
                ? '${prefs.quietHoursStartFormatted} - ${prefs.quietHoursEndFormatted}'
                : 'No notifications during this period',
            trailing: Switch(
              value: prefs.quietHoursEnabled,
              onChanged: preferencesService.setQuietHoursEnabled,
              activeColor: colors.accent,
              activeTrackColor: colors.accentMuted,
              inactiveThumbColor: colors.textTertiary,
              inactiveTrackColor: colors.surfaceHighlight,
            ),
            colors: colors,
          ),

          if (prefs.quietHoursEnabled) ...[
            _Divider(colors: colors),
            Padding(
              padding: const EdgeInsets.all(LedgerifySpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Start',
                      time: prefs.quietHoursStartFormatted,
                      onTap: () => _pickStartTime(context),
                      colors: colors,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.md,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: _TimePickerTile(
                      label: 'End',
                      time: prefs.quietHoursEndFormatted,
                      onTap: () => _pickEndTime(context),
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickStartTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: prefs.quietHoursStartHour,
        minute: prefs.quietHoursStartMinute,
      ),
    );

    if (time != null) {
      await preferencesService.setQuietHoursStart(time.hour, time.minute);
    }
  }

  void _pickEndTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: prefs.quietHoursEndHour,
        minute: prefs.quietHoursEndMinute,
      ),
    );

    if (time != null) {
      await preferencesService.setQuietHoursEnd(time.hour, time.minute);
    }
  }
}

// ============================================
// Reusable Widgets
// ============================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final LedgerifyColorScheme colors;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        icon,
        color: colors.textSecondary,
      ),
      title: Text(
        title,
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: LedgerifyTypography.labelSmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  final LedgerifyColorScheme colors;

  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: colors.surfaceHighlight,
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final LedgerifyColorScheme colors;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: LedgerifyRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(LedgerifySpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: LedgerifyRadius.borderRadiusMd,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: LedgerifyTypography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalXs,
            Text(
              time,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final LedgerifyColorScheme colors;

  const _ResetButton({
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          'Reset to Defaults',
          style: LedgerifyTypography.labelMedium.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
