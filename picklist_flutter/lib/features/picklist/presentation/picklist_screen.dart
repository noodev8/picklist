import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/search_bar.dart' hide FilterChip;
import '../../../core/widgets/search_bar.dart' as search_widgets;
import '../../../providers/picklist_provider.dart';
import '../../../models/pick_item.dart';
import 'widgets/pick_item_card.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/pick_stats_header.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  bool? _statusFilter;
  bool _hasActiveFilters = false;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

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
            _hasActiveFilters = statusFilter != null;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _hasActiveFilters = false;
      _searchQuery = '';
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PicklistProvider>(
        builder: (context, provider, _) {
          final filteredItems = provider.getFilteredItems(
            locationId: widget.locationId,
            isPicked: _statusFilter,
            searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          );

          return CustomScrollView(
            slivers: [
              _buildAppBar(provider),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    PickStatsHeader(
                      locationId: widget.locationId,
                      provider: provider,
                    ),
                    _buildSearchAndFilters(),
                    if (_hasActiveFilters || _searchQuery.isNotEmpty)
                      _buildActiveFilters(),
                  ],
                ),
              ),
              _buildPickList(filteredItems, provider),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
              case 'clear_filters':
                _clearFilters();
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
            if (_hasActiveFilters || _searchQuery.isNotEmpty)
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear, color: AppColors.textSecondary),
                    AppSpacing.horizontalSpaceSM,
                    Text('Clear Filters'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: CustomSearchBar(
        onSearchChanged: _onSearchChanged,
        hintText: 'Search picks...',
        onFilterPressed: _showFilterBottomSheet,
        hasActiveFilters: _hasActiveFilters,
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];
    
    if (_statusFilter != null) {
      filters.add(
        search_widgets.FilterChip(
          label: _statusFilter! ? 'Picked' : 'Pending',
          color: _statusFilter! ? AppColors.success : AppColors.warning,
          onRemove: () {
            setState(() {
              _statusFilter = null;
              _hasActiveFilters = false;
            });
          },
        ),
      );
    }

    if (_searchQuery.isNotEmpty) {
      filters.add(
        search_widgets.FilterChip(
          label: 'Search: $_searchQuery',
          onRemove: () {
            setState(() {
              _searchQuery = '';
            });
          },
        ),
      );
    }

    return search_widgets.FilterSection(
      filters: filters,
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
                    ).animate(animation),
                    child: Padding(
                      padding: AppSpacing.paddingVerticalSM,
                      child: PickItemCard(
                        item: item,
                        onToggle: () => provider.togglePickStatus(
                          widget.locationId,
                          item.id,
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.verticalSpaceMD,
          Text(
            'No picks found',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalSpaceSM,
          Text(
            _searchQuery.isNotEmpty || _hasActiveFilters
                ? 'Try adjusting your search or filters'
                : 'No picks available for this location',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _hasActiveFilters) ...[
            AppSpacing.verticalSpaceLG,
            CustomButton(
              text: 'Clear Filters',
              onPressed: _clearFilters,
              variant: ButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<PicklistProvider>(
      builder: (context, provider, _) {
        final items = provider.getPicksForLocation(widget.locationId);
        final hasUnpicked = items.any((item) => !item.isPicked);
        
        if (!hasUnpicked) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: _markAllAsPicked,
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark All Picked'),
          backgroundColor: AppColors.success,
        );
      },
    );
  }
}
