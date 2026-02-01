import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Goal Detail Screen - Ledgerify Design Language
///
/// A detailed view of a single savings goal with progress visualization,
/// contribution actions, and activity history.
class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  final GoalService goalService;

  const GoalDetailScreen({
    super.key,
    required this.goal,
    required this.goalService,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late String _goalId;

  @override
  void initState() {
    super.initState();
    _goalId = widget.goal.id;
  }

  Goal? _getCurrentGoal() {
    return widget.goalService.getGoal(_goalId);
  }

  void _showEditSheet(BuildContext context, Goal goal) {
    AddEditGoalSheet.show(
      context,
      goalService: widget.goalService,
      existingGoal: goal,
    );
  }

  Future<void> _deleteGoal(BuildContext context, Goal goal) async {
    final colors = LedgerifyColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        title: Text(
          'Delete Goal',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.name}"? This action cannot be undone.',
          style: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: LedgerifyTypography.labelLarge.copyWith(
                color: colors.negative,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await widget.goalService.deleteGoal(goal.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _reopenGoal(Goal goal) async {
    await widget.goalService.reopenGoal(goal.id);
  }

  void _showContributionSheet(BuildContext context, Goal goal) {
    final colors = LedgerifyColors.of(context);
    final amountController = TextEditingController();
    bool isValid = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(LedgerifyRadius.lg),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(LedgerifySpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textTertiary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    LedgerifySpacing.verticalMd,

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Contribution',
                          style: LedgerifyTypography.headlineMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(LedgerifySpacing.xs),
                            decoration: BoxDecoration(
                              color: colors.surfaceHighlight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    LedgerifySpacing.verticalXl,

                    // Remaining amount hint
                    Text(
                      'Remaining: ${CurrencyFormatter.format(goal.remainingAmount)}',
                      style: LedgerifyTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    LedgerifySpacing.verticalSm,

                    // Amount field
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: LedgerifyTypography.amountLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\u20B9 ',
                        prefixStyle: LedgerifyTypography.amountLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                        hintText: '0.00',
                        hintStyle: LedgerifyTypography.amountLarge.copyWith(
                          color: colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: colors.surfaceHighlight,
                        border: const OutlineInputBorder(
                          borderRadius: LedgerifyRadius.borderRadiusMd,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: LedgerifyRadius.borderRadiusMd,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: LedgerifyRadius.borderRadiusMd,
                          borderSide: BorderSide(
                            color: colors.accent,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: LedgerifySpacing.lg,
                          vertical: LedgerifySpacing.lg,
                        ),
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value.trim());
                        setSheetState(() {
                          isValid = amount != null && amount > 0;
                        });
                      },
                    ),
                    LedgerifySpacing.verticalXl,

                    // Save button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () async {
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                if (amount != null && amount > 0) {
                                  await widget.goalService.addContribution(
                                    goal.id,
                                    amount,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.background,
                          disabledBackgroundColor: colors.surfaceHighlight,
                          disabledForegroundColor: colors.textDisabled,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: LedgerifyRadius.borderRadiusMd,
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: LedgerifyTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isValid
                                ? colors.background
                                : colors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return ValueListenableBuilder<Box<Goal>>(
      valueListenable: widget.goalService.box.listenable(),
      builder: (context, box, _) {
        final goal = _getCurrentGoal();

        // Goal was deleted, pop back
        if (goal == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return Scaffold(backgroundColor: colors.background);
        }

        return Scaffold(
          backgroundColor: colors.background,
          appBar: _buildAppBar(context, colors, goal),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(LedgerifySpacing.lg),
            child: Column(
              children: [
                // Completed badge
                if (goal.isCompleted) ...[
                  _buildCompletedBadge(colors, goal),
                  LedgerifySpacing.verticalXl,
                ],

                // Circular progress
                _buildCircularProgress(colors, goal),
                LedgerifySpacing.verticalXl,

                // Amount progress
                _buildAmountProgress(colors, goal),
                LedgerifySpacing.verticalLg,

                // Linear progress bar
                _buildLinearProgress(colors, goal),
                LedgerifySpacing.verticalLg,

                // Deadline info
                if (goal.deadline != null) ...[
                  _buildDeadlineInfo(colors, goal),
                  LedgerifySpacing.verticalXl,
                ],

                // Add contribution button (only if not completed)
                if (!goal.isCompleted) ...[
                  LedgerifySpacing.verticalMd,
                  _buildAddContributionButton(context, colors, goal),
                  LedgerifySpacing.verticalXl,
                ],

                // Activity section
                _buildActivitySection(colors, goal),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    LedgerifyColorScheme colors,
    Goal goal,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        goal.name,
        style: LedgerifyTypography.headlineMedium.copyWith(
          color: colors.textPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colors.textPrimary,
          ),
          color: colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditSheet(context, goal);
                break;
              case 'delete':
                _deleteGoal(context, goal);
                break;
              case 'reopen':
                _reopenGoal(goal);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  LedgerifySpacing.horizontalMd,
                  Text(
                    'Edit',
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (goal.isCompleted)
              PopupMenuItem(
                value: 'reopen',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    LedgerifySpacing.horizontalMd,
                    Text(
                      'Reopen Goal',
                      style: LedgerifyTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: colors.negative,
                  ),
                  LedgerifySpacing.horizontalMd,
                  Text(
                    'Delete',
                    style: LedgerifyTypography.bodyLarge.copyWith(
                      color: colors.negative,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedBadge(LedgerifyColorScheme colors, Goal goal) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.15),
        borderRadius: LedgerifyRadius.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: colors.accent,
          ),
          LedgerifySpacing.horizontalSm,
          Text(
            'Goal Completed',
            style: LedgerifyTypography.labelLarge.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (goal.completedAt != null) ...[
            LedgerifySpacing.horizontalSm,
            Text(
              DateFormatter.format(goal.completedAt!),
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.accent.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularProgress(LedgerifyColorScheme colors, Goal goal) {
    // Clamp progress to 1.0 for display
    final displayProgress = goal.progress.clamp(0.0, 1.0);
    final percentText = '${(displayProgress * 100).toInt()}%';

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ring
          CustomPaint(
            painter: _CircularProgressPainter(
              progress: 1.0,
              color: colors.surfaceHighlight,
              strokeWidth: 12,
            ),
          ),
          // Progress ring
          CustomPaint(
            painter: _CircularProgressPainter(
              progress: displayProgress,
              color: goal.color,
              strokeWidth: 12,
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  percentText,
                  style: LedgerifyTypography.displaySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                LedgerifySpacing.verticalXs,
                Icon(
                  goal.icon,
                  size: 28,
                  color: goal.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountProgress(LedgerifyColorScheme colors, Goal goal) {
    return Column(
      children: [
        // Current / Target
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: CurrencyFormatter.format(goal.currentAmount),
                style: LedgerifyTypography.amountLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' of ',
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              TextSpan(
                text: CurrencyFormatter.format(goal.targetAmount),
                style: LedgerifyTypography.amountLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        LedgerifySpacing.verticalSm,
        // Remaining
        if (goal.remainingAmount > 0)
          Text(
            '${CurrencyFormatter.format(goal.remainingAmount)} remaining',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildLinearProgress(LedgerifyColorScheme colors, Goal goal) {
    final displayProgress = goal.progress.clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusFull,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: displayProgress,
        child: Container(
          decoration: BoxDecoration(
            color: goal.color,
            borderRadius: LedgerifyRadius.borderRadiusFull,
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineInfo(LedgerifyColorScheme colors, Goal goal) {
    final deadline = goal.deadline!;
    final now = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;

    String daysText;
    Color daysColor;

    if (goal.isCompleted) {
      daysText = '';
      daysColor = colors.textSecondary;
    } else if (daysLeft < 0) {
      daysText = '(${-daysLeft} days overdue)';
      daysColor = colors.negative;
    } else if (daysLeft == 0) {
      daysText = '(Due today)';
      daysColor = colors.warning;
    } else if (daysLeft == 1) {
      daysText = '(1 day left)';
      daysColor = colors.warning;
    } else {
      daysText = '($daysLeft days left)';
      daysColor = colors.textSecondary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: colors.textSecondary,
        ),
        LedgerifySpacing.horizontalSm,
        Text(
          'Due: ${DateFormatter.format(deadline)}',
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        if (daysText.isNotEmpty) ...[
          LedgerifySpacing.horizontalSm,
          Text(
            daysText,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: daysColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddContributionButton(
    BuildContext context,
    LedgerifyColorScheme colors,
    Goal goal,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _showContributionSheet(context, goal),
        icon: Icon(
          Icons.add_rounded,
          color: colors.background,
        ),
        label: Text(
          'Add Contribution',
          style: LedgerifyTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.background,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.background,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(LedgerifyColorScheme colors, Goal goal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LedgerifySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: LedgerifyRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: LedgerifyTypography.headlineSmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          LedgerifySpacing.verticalMd,

          // Started goal entry
          _ActivityItem(
            icon: Icons.flag_rounded,
            title: 'Started goal',
            date: DateFormatter.format(goal.createdAt),
            colors: colors,
          ),

          // Completed entry if applicable
          if (goal.isCompleted && goal.completedAt != null) ...[
            LedgerifySpacing.verticalSm,
            _ActivityItem(
              icon: Icons.check_circle_rounded,
              title: 'Goal completed',
              date: DateFormatter.format(goal.completedAt!),
              colors: colors,
              iconColor: colors.accent,
            ),
          ],

          LedgerifySpacing.verticalMd,

          // Placeholder for contribution history
          Text(
            '(Contribution history coming soon)',
            style: LedgerifyTypography.bodySmall.copyWith(
              color: colors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity item in the activity section
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final LedgerifyColorScheme colors;
  final Color? iconColor;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.colors,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? colors.textTertiary,
        ),
        LedgerifySpacing.horizontalSm,
        Text(
          title,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          date,
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
