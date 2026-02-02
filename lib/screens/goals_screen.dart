import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../widgets/goal_card.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/contribution_sheet.dart';
import '../theme/ledgerify_theme.dart';
import 'goal_detail_screen.dart';

/// Goals Screen - Ledgerify Design Language
///
/// The main screen for the Goals tab showing:
/// - Active goals section with GoalCards
/// - Completed goals section (collapsible)
/// - Empty state when no goals exist
/// - Add button in AppBar
class GoalsScreen extends StatefulWidget {
  final GoalService goalService;

  const GoalsScreen({
    super.key,
    required this.goalService,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _completedExpanded = false;

  void _openAddGoalSheet() {
    AddEditGoalSheet.show(
      context,
      goalService: widget.goalService,
    );
  }

  void _openGoalDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(
          goal: goal,
          goalService: widget.goalService,
        ),
      ),
    );
  }

  void _openContributionSheet(Goal goal) {
    ContributionSheet.show(
      context,
      goal: goal,
      goalService: widget.goalService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Goals',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: LedgerifySpacing.sm),
            child: IconButton(
              onPressed: _openAddGoalSheet,
              icon: Container(
                padding: const EdgeInsets.all(LedgerifySpacing.sm),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: LedgerifyRadius.borderRadiusSm,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: colors.background,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.goalService.box.listenable(),
        builder: (context, Box<Goal> box, _) {
          final activeGoals = widget.goalService.getActiveGoals();
          final completedGoals = widget.goalService.getCompletedGoals();

          // Empty state
          if (activeGoals.isEmpty && completedGoals.isEmpty) {
            return _buildEmptyState(colors);
          }

          return CustomScrollView(
            slivers: [
              // Active Goals Section
              if (activeGoals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    colors,
                    'Active Goals',
                    activeGoals.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = activeGoals[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < activeGoals.length - 1
                                ? LedgerifySpacing.md
                                : 0,
                          ),
                          child: GoalCard(
                            goal: goal,
                            onTap: () => _openGoalDetail(goal),
                            onAddContribution: () =>
                                _openContributionSheet(goal),
                          ),
                        );
                      },
                      childCount: activeGoals.length,
                    ),
                  ),
                ),
              ],

              // Spacing between sections
              if (activeGoals.isNotEmpty && completedGoals.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: LedgerifySpacing.xl),
                ),

              // Completed Goals Section (Collapsible)
              if (completedGoals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildCompletedSectionHeader(
                    colors,
                    completedGoals.length,
                  ),
                ),
                if (_completedExpanded)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerifySpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = completedGoals[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < completedGoals.length - 1
                                  ? LedgerifySpacing.md
                                  : 0,
                            ),
                            child: GoalCard(
                              goal: goal,
                              onTap: () => _openGoalDetail(goal),
                            ),
                          );
                        },
                        childCount: completedGoals.length,
                      ),
                    ),
                  ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: LedgerifySpacing.xxl),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 80,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalLg,
            Text(
              'No goals yet',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            LedgerifySpacing.verticalSm,
            Text(
              'Start saving for something special',
              textAlign: TextAlign.center,
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
            LedgerifySpacing.verticalXl,
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _openAddGoalSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerifySpacing.xl,
                  ),
                ),
                child: Text(
                  'Create a Goal',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: colors.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    LedgerifyColorScheme colors,
    String title,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: LedgerifySpacing.lg,
        right: LedgerifySpacing.lg,
        top: LedgerifySpacing.lg,
        bottom: LedgerifySpacing.md,
      ),
      child: Text(
        '$title ($count)',
        style: LedgerifyTypography.labelMedium.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompletedSectionHeader(
    LedgerifyColorScheme colors,
    int count,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _completedExpanded = !_completedExpanded;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(
          left: LedgerifySpacing.lg,
          right: LedgerifySpacing.lg,
          top: LedgerifySpacing.lg,
          bottom: LedgerifySpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Completed ($count)',
                style: LedgerifyTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _completedExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
