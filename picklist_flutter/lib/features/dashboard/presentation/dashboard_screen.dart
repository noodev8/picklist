import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

import '../../auth/state/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../picklist/presentation/picklist_screen.dart';
import '../../../providers/picklist_provider.dart';
import 'widgets/stats_card.dart';
import 'widgets/location_card.dart';

/// Modern dashboard screen with improved layout and statistics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _navigateToPicklist(String locationId, String locationName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PicklistScreen(
          locationId: locationId,
          locationName: locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsSection(),
                  AppSpacing.verticalSpaceLG,
                  _buildLocationsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Picklist Dashboard',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textOnPrimary,
          ),
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
        IconButton(
          icon: const Icon(
            Icons.logout,
            color: AppColors.textOnPrimary,
          ),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Consumer<PicklistProvider>(
      builder: (context, provider, _) {
        final totalPicks = provider.getTotalPicks();
        final completedPicks = provider.getCompletedPicks();
        final pendingPicks = totalPicks - completedPicks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: AppTypography.headlineMedium,
            ),
            AppSpacing.verticalSpaceMD,
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Pending',
                    value: pendingPicks.toString(),
                    icon: Icons.schedule,
                    color: AppColors.warning,
                  ),
                ),
                AppSpacing.horizontalSpaceMD,
                Expanded(
                  child: StatsCard(
                    title: 'Completed',
                    value: completedPicks.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationsSection() {
    return Consumer<PicklistProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pick Locations',
                  style: AppTypography.headlineMedium,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all locations view
                  },
                  child: Text(
                    'View All',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMD,
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.getSortedLocations().length,
              separatorBuilder: (context, index) => AppSpacing.verticalSpaceMD,
              itemBuilder: (context, index) {
                // Use sorted locations with completed ones at the bottom
                final sortedLocations = provider.getSortedLocations();
                final location = sortedLocations[index];
                final remainingPicks = provider.getRemainingPicksForLocation(location.id);
                final totalPicks = provider.getTotalPicksForLocation(location.id);

                return LocationCard(
                  location: location,
                  remainingPicks: remainingPicks,
                  totalPicks: totalPicks,
                  onTap: () => _navigateToPicklist(location.id, location.name),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
