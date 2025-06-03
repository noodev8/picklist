import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Statistics card widget for displaying key metrics
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMD,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMD,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusSM,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
              AppSpacing.verticalSpaceMD,
              Text(
                value,
                style: AppTypography.displaySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (subtitle != null) ...[
                AppSpacing.verticalSpaceXS,
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated stats card with number counting animation
class AnimatedStatsCard extends StatefulWidget {
  const AnimatedStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final Duration animationDuration;

  @override
  State<AnimatedStatsCard> createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return StatsCard(
          title: widget.title,
          value: _animation.value.toString(),
          icon: widget.icon,
          color: widget.color,
          subtitle: widget.subtitle,
          onTap: widget.onTap,
        );
      },
    );
  }
}

/// Compact stats card for smaller spaces
class CompactStatsCard extends StatelessWidget {
  const CompactStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.xs,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSM,
        child: Container(
          padding: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
