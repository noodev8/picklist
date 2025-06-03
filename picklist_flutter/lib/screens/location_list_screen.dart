import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/picklist_provider.dart';
import '../theme/app_theme.dart';
import 'pick_list_screen.dart';

class LocationListScreen extends StatelessWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PicklistProvider>(
      builder: (context, provider, _) {
        final totalPicks = provider.getTotalPicks();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Picklist'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  provider.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Total Picks Counter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    Text(
                      'Total Picks Remaining',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalPicks.toString(),
                      style: AppTheme.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Location List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.locations.length,
                  itemBuilder: (context, index) {
                    final location = provider.locations[index];
                    final remainingPicks = provider.getRemainingPicksForLocation(location.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PickListScreen(location: location),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location.name,
                                      style: AppTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$remainingPicks picks remaining',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
