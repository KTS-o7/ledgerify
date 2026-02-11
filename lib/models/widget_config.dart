import 'package:hive/hive.dart';

part 'widget_config.g.dart';

/// Update frequency options for the widget (in minutes).
enum WidgetUpdateFrequency {
  /// Manual only - updates when app is used
  manual(0, 'Manual only'),

  /// Every 30 minutes
  thirtyMinutes(30, 'Every 30 min'),

  /// Every hour
  oneHour(60, 'Every hour'),

  /// Every 2 hours
  twoHours(120, 'Every 2 hours'),

  /// Every 4 hours
  fourHours(240, 'Every 4 hours'),

  /// Every 6 hours
  sixHours(360, 'Every 6 hours');

  final int minutes;
  final String displayName;

  const WidgetUpdateFrequency(this.minutes, this.displayName);

  /// Get Duration for this frequency (null for manual)
  Duration? get duration => minutes > 0 ? Duration(minutes: minutes) : null;
}

/// Configuration for the home screen widget.
///
/// Stores user preferences for widget display:
/// - Quick-add category indices (which categories to show)
/// - Toggle for budget progress display
/// - Toggle for alerts display
/// - Update frequency
/// - Last sync timestamp
@HiveType(typeId: 17)
class WidgetConfig extends HiveObject {
  /// List of ExpenseCategory indices for quick-add buttons.
  /// Empty list = auto-learn from spending history.
  /// Max 4 categories.
  @HiveField(0)
  final List<int> quickAddCategories;

  /// Whether to show budget progress row on widget.
  @HiveField(1)
  final bool showBudgetProgress;

  /// Whether to show contextual alerts row on widget.
  @HiveField(2)
  final bool showAlerts;

  /// Last time the widget data was synced.
  @HiveField(3)
  final DateTime? lastSynced;

  /// Update frequency in minutes (0 = manual only).
  /// Maps to WidgetUpdateFrequency enum values.
  @HiveField(4)
  final int updateFrequencyMinutes;

  WidgetConfig({
    List<int>? quickAddCategories,
    this.showBudgetProgress = true,
    this.showAlerts = true,
    this.lastSynced,
    this.updateFrequencyMinutes = 120, // Default: 2 hours
  }) : quickAddCategories = quickAddCategories ?? [];

  /// Get the update frequency as enum.
  WidgetUpdateFrequency get updateFrequency {
    return WidgetUpdateFrequency.values.firstWhere(
      (f) => f.minutes == updateFrequencyMinutes,
      orElse: () => WidgetUpdateFrequency.twoHours,
    );
  }

  /// Whether auto-learn mode is active (no user-configured categories).
  bool get isAutoLearn => quickAddCategories.isEmpty;

  /// Whether periodic background updates are enabled.
  bool get hasPeriodicUpdates => updateFrequencyMinutes > 0;

  /// Check if a sync is due based on update frequency and last synced time.
  bool shouldSync() {
    if (!hasPeriodicUpdates) return false; // Manual mode - never auto-sync
    if (lastSynced == null) return true; // Never synced before

    final frequency = updateFrequency.duration;
    if (frequency == null) return false;

    final elapsed = DateTime.now().difference(lastSynced!);
    return elapsed >= frequency;
  }

  /// Creates a copy with optional field overrides.
  WidgetConfig copyWith({
    List<int>? quickAddCategories,
    bool? showBudgetProgress,
    bool? showAlerts,
    DateTime? lastSynced,
    int? updateFrequencyMinutes,
    bool clearQuickAddCategories = false,
  }) {
    return WidgetConfig(
      quickAddCategories: clearQuickAddCategories
          ? []
          : (quickAddCategories ?? this.quickAddCategories),
      showBudgetProgress: showBudgetProgress ?? this.showBudgetProgress,
      showAlerts: showAlerts ?? this.showAlerts,
      lastSynced: lastSynced ?? this.lastSynced,
      updateFrequencyMinutes:
          updateFrequencyMinutes ?? this.updateFrequencyMinutes,
    );
  }

  /// Converts to JSON for debugging/export.
  Map<String, dynamic> toJson() {
    return {
      'quickAddCategories': quickAddCategories,
      'showBudgetProgress': showBudgetProgress,
      'showAlerts': showAlerts,
      'lastSynced': lastSynced?.toIso8601String(),
      'updateFrequencyMinutes': updateFrequencyMinutes,
    };
  }

  /// Creates from JSON.
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      quickAddCategories:
          (json['quickAddCategories'] as List<dynamic>?)?.cast<int>() ?? [],
      showBudgetProgress: json['showBudgetProgress'] as bool? ?? true,
      showAlerts: json['showAlerts'] as bool? ?? true,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      updateFrequencyMinutes: json['updateFrequencyMinutes'] as int? ?? 120,
    );
  }

  @override
  String toString() {
    return 'WidgetConfig(categories: $quickAddCategories, showBudget: $showBudgetProgress, showAlerts: $showAlerts)';
  }
}
