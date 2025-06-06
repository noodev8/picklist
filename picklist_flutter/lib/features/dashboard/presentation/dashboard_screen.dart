import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/auth_error_handler.dart';

import '../../auth/state/auth_provider.dart';
import '../../splash/presentation/splash_screen.dart';
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
    _loadPicksAfterLogin();
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

  /// Load all picks data immediately after dashboard loads
  /// This ensures users can see pick counts for all locations right away
  /// instead of having to click on each location to see if there are picks
  Future<void> _loadPicksAfterLogin() async {
    try {
      // Get the picklist provider and load all picks data
      final picklistProvider = context.read<PicklistProvider>();

      // Load all picks data in the background
      // This will update location counts and pre-load pick data
      await picklistProvider.loadAllPicksAfterLogin();
    } on AuthenticationException catch (authError) {
      // Handle authentication error by redirecting to login
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(
          context,
          authError.response,
          showMessage: true,
        );
      }
    } catch (e) {
      // Handle other errors silently - the provider will show error messages
      // We don't want to interrupt the dashboard loading for non-auth errors
    }
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
              const SplashScreen(),
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

  /// Refresh all dashboard data by reloading picks and location counts
  /// This method is called when user pulls down to refresh
  Future<void> _refreshDashboard() async {
    try {
      // Get the picklist provider and refresh all data
      final picklistProvider = context.read<PicklistProvider>();

      // Debug: Print current stats before refresh
      print('Dashboard Refresh - Before: Total=${picklistProvider.getTotalPicks()}, Completed=${picklistProvider.getCompletedPicks()}');

      // Refresh all picks data and location counts
      // This will update the dashboard with latest information including completed/pending stats
      await picklistProvider.loadAllPicksAfterLogin();

      // Debug: Print stats after refresh
      print('Dashboard Refresh - After: Total=${picklistProvider.getTotalPicks()}, Completed=${picklistProvider.getCompletedPicks()}');

      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dashboard refreshed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } on AuthenticationException catch (authError) {
      // Handle authentication error by redirecting to login
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(
          context,
          authError.response,
          showMessage: true,
        );
      }
    } catch (e) {
      // Show error message for other types of errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          // Add pull-to-refresh functionality to dashboard
          onRefresh: _refreshDashboard,
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
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,  // Changed from false to true to allow pull-to-refresh
      pinned: false,   // Changed from true to false to allow pull-to-refresh
      snap: true,      // Added snap behavior for better UX
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
            // Removed 'Pick Locations' title and 'View All' button to save space
            // and provide cleaner UX for picking workflow
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
