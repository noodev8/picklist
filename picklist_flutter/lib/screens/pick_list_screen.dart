import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/pick_location.dart';
import '../models/pick_item.dart';
import '../providers/picklist_provider.dart';
import '../theme/app_theme.dart';

class PickListScreen extends StatefulWidget {
  final PickLocation location;

  const PickListScreen({
    super.key,
    required this.location,
  });

  @override
  State<PickListScreen> createState() => _PickListScreenState();
}

class _PickListScreenState extends State<PickListScreen> {
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PicklistProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.location.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadPicksForLocation(widget.location.id, forceRefresh: true),
              ),
            ],
          ),
          body: FutureBuilder<List<PickItem>>(
            future: provider.getPicksForLocation(widget.location.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading picks',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final picks = snapshot.data ?? [];
              final remainingPicks = picks.where((item) => !item.isPicked).length;

              if (picks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No picks available',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All items in this location have been picked',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Header with remaining picks count
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      '$remainingPicks remaining picks',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Picks list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: picks.length,
                      itemBuilder: (context, index) {
                        final item = picks[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: item.isPicked ? AppTheme.successColor.withValues(alpha: 0.1) : null,
                          child: InkWell(
                            onTap: () => provider.togglePickStatus(widget.location.id, item.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isPicked ? AppTheme.successColor : Colors.transparent,
                            border: Border.all(
                              color: item.isPicked ? AppTheme.successColor : AppTheme.textSecondary,
                              width: 2,
                            ),
                          ),
                          child: item.isPicked
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productCode,
                                style: AppTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                style: AppTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Location: ${item.location}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Image preview button
                        if (item.imageUrl != null)
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: () => _showImageDialog(context, item.imageUrl!),
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
              );
            },
          ),
        );
      },
    );
  }
}
