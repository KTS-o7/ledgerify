import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/goal.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Goal Card - Ledgerify Design Language
///
/// Displays a savings goal with circular progress indicator.
/// Shows goal name, target amount, progress, remaining amount,
/// and optional deadline. Follows "Quiet Finance" design philosophy.
class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onAddContribution;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onAddContribution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: LedgerifyRadius.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Circular progress + Goal info + Remaining amount
            _buildTopRow(colors),
            LedgerifySpacing.verticalMd,
            // Linear progress bar + Quick add button
            _buildProgressRow(colors),
            LedgerifySpacing.verticalSm,
            // Deadline footer
            _buildDeadlineFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(LedgerifyColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circular progress indicator
        _buildCircularProgress(colors),
        LedgerifySpacing.horizontalMd,
        // Goal name and target
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.name,
                style: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              LedgerifySpacing.verticalXs,
              Text(
                '${CurrencyFormatter.format(goal.targetAmount)} goal',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        LedgerifySpacing.horizontalSm,
        // Remaining amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(goal.remainingAmount),
              style: LedgerifyTypography.amountMedium.copyWith(
                color: goal.isCompleted ? colors.accent : colors.textPrimary,
              ),
            ),
            LedgerifySpacing.verticalXs,
            Text(
              goal.isCompleted ? 'completed' : 'remaining',
              style: LedgerifyTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularProgress(LedgerifyColorScheme colors) {
    final progressPercent = (goal.progress * 100).clamp(0, 999).toInt();
    final progressColor = _getProgressColor(colors);
    final trackColor = colors.surfaceHighlight;

    return SizedBox(
      width: 64,
      height: 64,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background track
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: goal.progress.clamp(0.0, 1.0),
                  progressColor: progressColor,
                  trackColor: trackColor,
                  strokeWidth: 5,
                ),
              ),
            ),
            // Center content: percentage or checkmark
            if (goal.isCompleted)
              Icon(
                Icons.check_rounded,
                size: 28,
                color: colors.accent,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$progressPercent%',
                    style: LedgerifyTypography.labelLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    goal.icon,
                    size: 16,
                    color: progressColor,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(LedgerifyColorScheme colors) {
    final progressColor = _getProgressColor(colors);

    return Row(
      children: [
        // Linear progress bar
        Expanded(
          child: _buildLinearProgressBar(progressColor, colors),
        ),
        LedgerifySpacing.horizontalMd,
        // Quick add button
        if (!goal.isCompleted && onAddContribution != null)
          GestureDetector(
            onTap: onAddContribution,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accentMuted,
                borderRadius: LedgerifyRadius.borderRadiusSm,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: colors.accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLinearProgressBar(
    Color progressColor,
    LedgerifyColorScheme colors,
  ) {
    final clampedProgress = goal.progress.clamp(0.0, 1.0);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: colors.surfaceHighlight,
        borderRadius: LedgerifyRadius.borderRadiusFull,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * clampedProgress,
                height: 6,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: LedgerifyRadius.borderRadiusFull,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeadlineFooter(LedgerifyColorScheme colors) {
    final deadlineText = _getDeadlineText();
    final deadlineColor = goal.isOverdue ? colors.warning : colors.textTertiary;

    return Row(
      children: [
        Icon(
          goal.isOverdue
              ? Icons.warning_amber_rounded
              : Icons.calendar_today_outlined,
          size: 14,
          color: deadlineColor,
        ),
        LedgerifySpacing.horizontalXs,
        Text(
          deadlineText,
          style: LedgerifyTypography.bodySmall.copyWith(
            color: deadlineColor,
          ),
        ),
      ],
    );
  }

  String _getDeadlineText() {
    if (goal.isCompleted && goal.completedAt != null) {
      return 'Completed ${DateFormatter.format(goal.completedAt!)}';
    }
    if (goal.deadline == null) {
      return 'No deadline';
    }
    if (goal.isOverdue) {
      return 'Overdue since ${DateFormatter.format(goal.deadline!)}';
    }
    return 'Due: ${DateFormatter.format(goal.deadline!)}';
  }

  Color _getProgressColor(LedgerifyColorScheme colors) {
    if (goal.isCompleted) {
      return colors.accent;
    }
    if (goal.isOverdue) {
      return colors.warning;
    }
    return goal.color;
  }
}

/// Custom painter for the circular progress indicator.
/// Draws a track and progress arc with smooth rendering.
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2; // Start from top

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
