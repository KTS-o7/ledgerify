import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';

/// Service class for managing savings goals with Hive local storage.
///
/// This service provides CRUD operations for savings goals, including
/// contribution management and goal completion tracking.
class GoalService {
  static const Uuid _uuid = Uuid();

  final Box<Goal> _goalBox;

  /// Creates a GoalService with the given Hive box.
  GoalService(this._goalBox);

  /// Returns the listenable box for reactive UI updates.
  /// Use this with ValueListenableBuilder to rebuild UI on data changes.
  Box<Goal> get box => _goalBox;

  /// Generates a new unique ID for a goal.
  String generateId() => _uuid.v4();

  /// Retrieves all goals, sorted by createdAt (newest first).
  List<Goal> getAllGoals() {
    final goals = _goalBox.values.toList();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// Retrieves only active (non-completed) goals, sorted by createdAt (newest first).
  List<Goal> getActiveGoals() {
    final goals = _goalBox.values.where((goal) => !goal.isCompleted).toList();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// Retrieves only completed goals, sorted by createdAt (newest first).
  List<Goal> getCompletedGoals() {
    final goals = _goalBox.values.where((goal) => goal.isCompleted).toList();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// Retrieves a single goal by ID.
  /// Returns null if not found.
  Goal? getGoal(String id) {
    return _goalBox.get(id);
  }

  /// Creates a new goal with the given parameters.
  /// Returns the created goal.
  Future<Goal> createGoal({
    required String name,
    required double targetAmount,
    required int iconCodePoint,
    required String colorHex,
    DateTime? deadline,
  }) async {
    final goal = Goal(
      id: generateId(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      deadline: deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await _goalBox.put(goal.id, goal);
    return goal;
  }

  /// Updates an existing goal.
  Future<void> updateGoal(Goal goal) async {
    await _goalBox.put(goal.id, goal);
  }

  /// Deletes a goal by ID.
  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
  }

  /// Adds a contribution to a goal.
  /// Automatically marks the goal as completed if target is reached.
  Future<void> addContribution(String goalId, double amount) async {
    final goal = _goalBox.get(goalId);
    if (goal == null) return;

    final newAmount = goal.currentAmount + amount;
    final isNowCompleted = newAmount >= goal.targetAmount;

    final updatedGoal = goal.copyWith(
      currentAmount: newAmount,
      isCompleted: isNowCompleted || goal.isCompleted,
    );

    await _goalBox.put(goalId, updatedGoal);
  }

  /// Withdraws a contribution from a goal (for corrections).
  /// Ensures the amount doesn't go below zero.
  Future<void> withdrawContribution(String goalId, double amount) async {
    final goal = _goalBox.get(goalId);
    if (goal == null) return;

    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);

    final updatedGoal = goal.copyWith(
      currentAmount: newAmount,
    );

    await _goalBox.put(goalId, updatedGoal);
  }

  /// Manually marks a goal as completed.
  Future<void> markCompleted(String goalId) async {
    final goal = _goalBox.get(goalId);
    if (goal == null) return;

    final updatedGoal = goal.copyWith(isCompleted: true);
    await _goalBox.put(goalId, updatedGoal);
  }

  /// Reopens a completed goal.
  Future<void> reopenGoal(String goalId) async {
    final goal = _goalBox.get(goalId);
    if (goal == null) return;

    final updatedGoal = goal.copyWith(isCompleted: false);
    await _goalBox.put(goalId, updatedGoal);
  }
}
