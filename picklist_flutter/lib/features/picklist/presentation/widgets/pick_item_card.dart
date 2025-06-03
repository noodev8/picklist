import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../models/pick_item.dart';

/// Enhanced pick item card with better visual design and interactions
class PickItemCard extends StatelessWidget {
  const PickItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  final PickItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.radiusMD,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMD,
            border: Border.all(
              color: item.isPicked 
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
              width: item.isPicked ? 2 : 1,
            ),
            color: item.isPicked 
                ? AppColors.success.withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              _buildStatusIndicator(),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: _buildItemDetails(),
              ),
              if (item.imageUrl != null) ...[
                AppSpacing.horizontalSpaceMD,
                _buildImagePreview(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isPicked ? AppColors.success : Colors.transparent,
        border: Border.all(
          color: item.isPicked ? AppColors.success : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: item.isPicked
          ? const Icon(
              Icons.check,
              color: AppColors.textOnPrimary,
              size: 18,
            )
          : null,
    );
  }

  Widget _buildItemDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.productCode,
                style: AppTypography.titleLarge.copyWith(
                  decoration: item.isPicked ? TextDecoration.lineThrough : null,
                  color: item.isPicked 
                      ? AppColors.textSecondary 
                      : AppColors.textPrimary,
                ),
              ),
            ),
            StatusChip(
              status: item.isPicked ? PickStatus.picked : PickStatus.pending,
              size: ChipSize.small,
            ),
          ],
        ),
        AppSpacing.verticalSpaceXS,
        Text(
          item.title,
          style: AppTypography.bodyMedium.copyWith(
            decoration: item.isPicked ? TextDecoration.lineThrough : null,
            color: item.isPicked 
                ? AppColors.textTertiary 
                : AppColors.textPrimary,
          ),
        ),
        AppSpacing.verticalSpaceXS,
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: AppColors.textSecondary,
            ),
            AppSpacing.horizontalSpaceXS,
            Text(
              item.location,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageDialog(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusSM,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.radiusSM,
          child: CachedNetworkImage(
            imageUrl: item.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(
                Icons.image,
                color: AppColors.textSecondary,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(
                Icons.broken_image,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.radiusLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: AppSpacing.paddingMD,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productCode,
                            style: AppTypography.titleLarge,
                          ),
                          Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMD,
                  child: ClipRRect(
                    borderRadius: AppRadius.radiusMD,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.verticalSpaceSM,
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
