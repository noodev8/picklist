import 'package:flutter/material.dart' hide FilterChip;
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../providers/picklist_provider.dart';
import '../../../models/pick_item.dart';
import 'widgets/pick_item_card.dart';
import 'widgets/pick_stats_header.dart';
import 'widgets/filter_bottom_sheet.dart';

/// Enhanced picklist screen with search, filtering, and better UX
class PicklistScreen extends StatefulWidget {
  const PicklistScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  State<PicklistScreen> createState() => _PicklistScreenState();
}

class _PicklistScreenState extends State<PicklistScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pickAnimationController;

  // Filter state variables (removed search query)
  bool? _statusFilter; // null = all, true = picked, false = unpicked

  // Enhanced animation tracking for picked items
  final Map<String, AnimationController> _itemAnimations = {};
  final Set<String> _itemsBeingAnimated = <String>{};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pickAnimationController.dispose();
    // Dispose all item-specific animation controllers
    for (final controller in _itemAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markAllAsPicked() {
    final provider = context.read<PicklistProvider>();
    provider.markAllAsPicked(widget.locationId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All items marked as picked'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _markAllAsUnpicked() {
    final provider = context.read<PicklistProvider>();
    provider.markAllAsUnpicked(widget.locationId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All items marked as unpicked'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // Helper method to get filtered items based on current filter state
  List<PickItem> _getFilteredItems(PicklistProvider provider) {
    return provider.getFilteredItems(
      locationId: widget.locationId,
      isPicked: _statusFilter,
      searchQuery: null, // No search functionality
    );
  }

  // Method to show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentStatusFilter: _statusFilter,
        onFiltersApplied: (statusFilter) {
          setState(() {
            _statusFilter = statusFilter;
          });
        },
      ),
    );
  }

  // Enhanced method to handle item toggle with smooth animation
  void _togglePickStatusWithAnimation(String itemId) async {
    final provider = context.read<PicklistProvider>();
    final item = provider.getPicksForLocation(widget.locationId)
        .firstWhere((item) => item.id == itemId);

    // Store the original status to determine what action is being performed
    final wasPickedBefore = item.isPicked;

    // Create animation controller for this specific item if it doesn't exist
    if (!_itemAnimations.containsKey(itemId)) {
      _itemAnimations[itemId] = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    }

    final animationController = _itemAnimations[itemId]!;

    // Add item to animation tracking
    setState(() {
      _itemsBeingAnimated.add(itemId);
    });

    // If item is being picked (not unpicked), play success animation
    if (!wasPickedBefore) {
      // Start the pick animation (scale + fade effect)
      animationController.forward();

      // Wait for animation to reach halfway point before toggling status
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Toggle the status in the provider
    provider.togglePickStatus(widget.locationId, itemId);

    // If filtering by pending only and item was just picked, wait for animation to complete
    if (_statusFilter == false && !wasPickedBefore) {
      // Item was just picked, wait for full animation before allowing filter to hide it
      await Future.delayed(const Duration(milliseconds: 600));
    } else {
      // For other cases, shorter delay
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Clean up animation state if widget is still mounted
    if (mounted) {
      setState(() {
        _itemsBeingAnimated.remove(itemId);
      });
      // Reset animation controller for reuse
      animationController.reset();
    }
  }

  // Method to clear all filters
  void _clearFilters() {
    setState(() {
      _statusFilter = null;
    });
  }

  // Helper method to check if any filters are active
  bool _hasActiveFilters() {
    return _statusFilter != null;
  }

  // Helper method to get filter label text
  String? _getFilterLabel() {
    if (_statusFilter == null) return null;
    return _statusFilter! ? 'Picked Only' : 'Pending Only';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PicklistProvider>(
        builder: (context, provider, _) {
          final items = _getFilteredItems(provider);

          return CustomScrollView(
            slivers: [
              _buildAppBar(provider),
              SliverToBoxAdapter(
                child: PickStatsHeader(
                  locationId: widget.locationId,
                  provider: provider,
                ),
              ),
              _buildFilterSection(),
              _buildPickList(items, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(PicklistProvider provider) {
    final remainingPicks = provider.getRemainingPicksForLocation(widget.locationId);
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.locationName,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            Text(
              '$remainingPicks remaining',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textOnPrimary,
          ),
          onSelected: (value) {
            switch (value) {
              case 'mark_all_picked':
                _markAllAsPicked();
                break;
              case 'mark_all_unpicked':
                _markAllAsUnpicked();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_picked',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  AppSpacing.horizontalSpaceSM,
                  Text('Mark All Picked'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_all_unpicked',
              child: Row(
                children: [
                  Icon(Icons.radio_button_unchecked, color: AppColors.warning),
                  AppSpacing.horizontalSpaceSM,
                  Text('Mark All Unpicked'),
                ],
              ),
            ),
          ],
        ),      ],
    );
  }
  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Picks',
                  style: AppTypography.titleLarge,
                ),
                // Filter button
                Container(
                  decoration: BoxDecoration(
                    color: _hasActiveFilters() 
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: AppRadius.radiusMD,
                    border: Border.all(
                      color: _hasActiveFilters() 
                          ? AppColors.primary 
                          : AppColors.border,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _showFilterBottomSheet,
                    icon: Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters() 
                          ? AppColors.primary 
                          : AppColors.textSecondary,
                    ),
                    tooltip: 'Filter picks',
                  ),
                ),
              ],
            ),
            
            // Active filters display
            if (_hasActiveFilters()) ...[
              AppSpacing.verticalSpaceMD,
              _buildActiveFilters(),
            ],
            
            AppSpacing.verticalSpaceMD,
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filterChips = <Widget>[];
    
    // Add status filter chip if active
    final statusLabel = _getFilterLabel();
    if (statusLabel != null) {
      filterChips.add(
        FilterChip(
          label: statusLabel,
          onRemove: () {
            setState(() {
              _statusFilter = null;
            });
          },
          color: _statusFilter! ? AppColors.success : AppColors.warning,
        ),
      );
    }
    
    return FilterSection(
      filters: filterChips,
      onClearAll: _clearFilters,
    );
  }

  Widget _buildPickList(List<PickItem> items, PicklistProvider provider) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: AppSpacing.screenPadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                ));

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),                    child: Padding(
                      padding: AppSpacing.paddingVerticalSM,
                      child: _buildAnimatedPickItem(item),
                    ),
                  ),
                );
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // Enhanced animated pick item with success feedback
  Widget _buildAnimatedPickItem(PickItem item) {
    final isBeingAnimated = _itemsBeingAnimated.contains(item.id);
    final animationController = _itemAnimations[item.id];

    if (isBeingAnimated && animationController != null) {
      // Create success animation with scale and color effects
      final scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ));

      final fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ));

      return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: AnimatedOpacity(
              opacity: fadeAnimation.value,
              duration: const Duration(milliseconds: 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.radiusMD,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 8 * scaleAnimation.value,
                      spreadRadius: 2 * scaleAnimation.value,
                    ),
                  ],
                ),
                child: PickItemCard(
                  item: item,
                  onToggle: () => _togglePickStatusWithAnimation(item.id),
                ),
              ),
            ),
          );
        },
      );
    }

    // Default state - no animation
    return AnimatedOpacity(
      opacity: isBeingAnimated ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: PickItemCard(
        item: item,
        onToggle: () => _togglePickStatusWithAnimation(item.id),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Check if it's because of filters or genuinely no items
    final hasFilters = _hasActiveFilters();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.list,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.verticalSpaceMD,
          Text(
            hasFilters ? 'No picks found' : 'No picks available',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalSpaceSM,
          Text(
            hasFilters 
                ? 'Try adjusting your filter'
                : 'No picks available for this location',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            AppSpacing.verticalSpaceLG,
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Clear Filter',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
