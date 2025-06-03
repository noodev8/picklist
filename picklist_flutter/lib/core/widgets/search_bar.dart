import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Custom search bar widget with filtering capabilities
class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Search...',
    this.onFilterPressed,
    this.hasActiveFilters = false,
    this.enabled = true,
  });

  final ValueChanged<String> onSearchChanged;
  final String hintText;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;
  final bool enabled;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: _focusNode.hasFocus ? AppColors.primary : AppColors.border,
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: AppSpacing.paddingHorizontalMD,
            child: Icon(
              Icons.search,
              color: _focusNode.hasFocus 
                  ? AppColors.primary 
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          
          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: AppSpacing.paddingVerticalSM,
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          
          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              color: AppColors.textSecondary,
              iconSize: 20,
              onPressed: () {
                _controller.clear();
                widget.onSearchChanged('');
              },
            ),
          
          // Filter button
          if (widget.onFilterPressed != null) ...[
            Container(
              height: 24,
              width: 1,
              color: AppColors.border,
              margin: AppSpacing.paddingHorizontalSM,
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: widget.hasActiveFilters 
                    ? AppColors.primary 
                    : AppColors.textSecondary,
              ),
              iconSize: 20,
              onPressed: widget.onFilterPressed,
            ),
          ],
        ],
      ),
    );
  }
}

/// Filter chip widget for displaying active filters
class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.color,
  });

  final String label;
  final VoidCallback onRemove;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSM,
        border: Border.all(
          color: (color ?? AppColors.primary).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.horizontalSpaceXS,
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter section widget for organizing filter chips
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.filters,
    this.onClearAll,
  });

  final List<Widget> filters;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear All',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.verticalSpaceSM,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: filters,
          ),
        ],
      ),
    );
  }
}
