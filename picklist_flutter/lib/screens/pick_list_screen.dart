import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/pick_location.dart';
import '../models/pick_item.dart';
import '../providers/picklist_provider.dart';
import '../theme/app_theme.dart';

class PickListScreen extends StatelessWidget {
  final PickLocation location;

  const PickListScreen({
    super.key,
    required this.location,
  });

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
        final picks = provider.getPicksForLocation(location.id);
        final remainingPicks = provider.getRemainingPicksForLocation(location.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(location.name),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$remainingPicks remaining picks',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: picks.length,
            itemBuilder: (context, index) {
              final item = picks[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: item.isPicked ? AppTheme.successColor.withOpacity(0.1) : null,
                child: InkWell(
                  onTap: () => provider.togglePickStatus(location.id, item.id),
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
        );
      },
    );
  }
}
