import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';

/// Bottom sheet for filtering pick items
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    this.currentStatusFilter,
    required this.onFiltersApplied,
  });

  final bool? currentStatusFilter;
  final Function(bool? statusFilter) onFiltersApplied;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  bool? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.currentStatusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildContent(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: AppSpacing.paddingVerticalSM,
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: AppRadius.radiusXS,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppSpacing.paddingHorizontalLG,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filter Picks',
              style: AppTypography.headlineMedium,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: AppTypography.titleMedium,
          ),
          AppSpacing.verticalSpaceMD,
          _buildStatusOptions(),
          AppSpacing.verticalSpaceLG,
        ],
      ),
    );
  }

  Widget _buildStatusOptions() {
    return Column(
      children: [
        _buildStatusOption(
          title: 'All Items',
          subtitle: 'Show both picked and pending items',
          value: null,
          icon: Icons.list,
        ),
        AppSpacing.verticalSpaceSM,
        _buildStatusOption(
          title: 'Pending Only',
          subtitle: 'Show only items that need to be picked',
          value: false,
          icon: Icons.schedule,
          color: AppColors.warning,
        ),
        AppSpacing.verticalSpaceSM,
        _buildStatusOption(
          title: 'Picked Only',
          subtitle: 'Show only completed items',
          value: true,
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required bool? value,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = _statusFilter == value;
    
    return Card(
      elevation: isSelected ? AppElevation.sm : AppElevation.xs,
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = value;
          });
        },
        borderRadius: AppRadius.radiusMD,
        child: Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMD,
            border: Border.all(
              color: isSelected 
                  ? (color ?? AppColors.primary)
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
                ? (color ?? AppColors.primary).withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Icon(
                  icon,
                  color: color ?? AppColors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected 
                            ? (color ?? AppColors.primary)
                            : AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalSpaceXS,
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color ?? AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Clear',
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                });
              },
              variant: ButtonVariant.secondary,
            ),
          ),
          AppSpacing.horizontalSpaceMD,
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Apply Filters',
              onPressed: () {
                widget.onFiltersApplied(_statusFilter);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
