import 'package:flutter/foundation.dart';
import '../models/pick_item.dart';
import '../models/pick_location.dart';
import '../api/get_picks_api.dart';
import '../api/set_picked_api.dart';
import '../core/utils/auth_error_handler.dart';

class PicklistProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  // Cache for pick items by location
  final Map<String, List<PickItem>> _pickItems = {};

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Location data - will be populated from API data
  List<PickLocation> _locations = [];

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PickLocation> get locations => _locations;

  PicklistProvider() {
    _initializeLocations();
  }

  /// Initialize locations with default values
  /// These will be updated with real counts from API
  void _initializeLocations() {
    _locations = [
      PickLocation(id: 'c3f', name: 'C3-Front', totalPicks: 0),
      PickLocation(id: 'c3b', name: 'C3-Back', totalPicks: 0),
      PickLocation(id: 'c3c', name: 'C3-Crocs', totalPicks: 0),
      PickLocation(id: 'c3s', name: 'C3-Shop', totalPicks: 0),
      PickLocation(id: 'c1', name: 'C1', totalPicks: 0),
    ];
  }

  // Authentication is now handled by AuthProvider
  // This provider focuses on pick data management

  Future<void> logout() async {
    _isAuthenticated = false;
    // Clear cached data on logout
    _pickItems.clear();
    _initializeLocations();
    notifyListeners();
  }

  /// Loads picks for a specific location from the API
  ///
  /// [locationId] - The location ID to load picks for
  /// [forceRefresh] - Whether to force refresh even if data is cached
  /// [suppressNotifications] - Whether to suppress notifyListeners calls (for batch operations)
  Future<void> loadPicksForLocation(String locationId, {bool forceRefresh = false, bool suppressNotifications = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _pickItems.containsKey(locationId)) {
      return;
    }

    // Only set loading state if not suppressing notifications
    if (!suppressNotifications) {
      _setLoading(true);
      _clearError();
    }

    try {
      // Get picks from API for this location
      final List<PickItem> picks = await GetPicksApi.getPicksForLocation(locationId);

      // Cache the picks
      _pickItems[locationId] = picks;

      // Update location total picks count (suppress notifications if requested)
      if (suppressNotifications) {
        _updateLocationPickCountSilent(locationId, picks.length);
      } else {
        _updateLocationPickCount(locationId, picks.length);
      }

    } on AuthenticationException {
      // Re-throw authentication exceptions so they can be handled by the UI
      if (!suppressNotifications) {
        _setError('Authentication failed');
      }
      _pickItems[locationId] = [];
      rethrow;
    } catch (e) {
      if (!suppressNotifications) {
        _setError('Failed to load picks: ${e.toString()}');
      }
      // Ensure empty list if error occurs
      _pickItems[locationId] = [];
    } finally {
      // Only set loading state if not suppressing notifications
      if (!suppressNotifications) {
        _setLoading(false);
      }
    }
  }

  /// Gets picks for a location (loads from API if not cached)
  Future<List<PickItem>> getPicksForLocation(String locationId) async {
    // Load from API if not cached
    if (!_pickItems.containsKey(locationId)) {
      await loadPicksForLocation(locationId);
    }

    final items = _pickItems[locationId] ?? [];
    // Sort items by rack location for better picker workflow
    items.sort((a, b) => a.location.compareTo(b.location));
    return items;
  }

  /// Gets all picks across all locations
  Future<List<PickItem>> getAllPicks() async {
    final allItems = <PickItem>[];
    for (final items in _pickItems.values) {
      allItems.addAll(items);
    }
    // Sort items by rack location for better picker workflow
    allItems.sort((a, b) => a.location.compareTo(b.location));
    return allItems;
  }

  /// Toggles the picked status of an item using the API
  Future<void> togglePickStatus(String locationId, String pickId) async {
    _setLoading(true);
    _clearError();

    try {
      // Find the item in cache
      final items = _pickItems[locationId];
      if (items != null) {
        final itemIndex = items.indexWhere((item) => item.id == pickId);
        if (itemIndex != -1) {
          final item = items[itemIndex];

          // Call API to update status
          await SetPickedApi.togglePickedStatus(pickId, item.isPicked);

          // Update local cache
          items[itemIndex].isPicked = !items[itemIndex].isPicked;

          notifyListeners();
        }
      }
    } on AuthenticationException {
      // Re-throw authentication exceptions so they can be handled by the UI
      _setError('Authentication failed');
      rethrow;
    } catch (e) {
      _setError('Failed to update pick status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggles the picked status of an item by searching across all locations
  /// Used when showing all picks and we don't know which location the item belongs to
  Future<void> togglePickStatusGlobally(String pickId) async {
    _setLoading(true);
    _clearError();

    try {
      // Find the item across all locations
      PickItem? foundItem;
      String? foundLocationId;

      for (final entry in _pickItems.entries) {
        final locationId = entry.key;
        final items = entry.value;
        final itemIndex = items.indexWhere((item) => item.id == pickId);
        if (itemIndex != -1) {
          foundItem = items[itemIndex];
          foundLocationId = locationId;
          break;
        }
      }

      if (foundItem != null && foundLocationId != null) {
        // Call API to update status
        await SetPickedApi.togglePickedStatus(pickId, foundItem.isPicked);

        // Update local cache
        foundItem.isPicked = !foundItem.isPicked;

        notifyListeners();
      }
    } on AuthenticationException {
      // Re-throw authentication exceptions so they can be handled by the UI
      _setError('Authentication failed');
      rethrow;
    } catch (e) {
      _setError('Failed to update pick status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  int getTotalPicks() {
    return locations.fold(0, (sum, location) => sum + location.totalPicks);
  }

  int getRemainingPicksForLocation(String locationId) {
    final items = _pickItems[locationId];
    if (items == null) return 0;
    return items.where((item) => !item.isPicked).length;
  }

  int getTotalPicksForLocation(String locationId) {
    final items = _pickItems[locationId];
    return items?.length ?? 0;
  }

  int getCompletedPicks() {
    int completed = 0;
    for (final items in _pickItems.values) {
      completed += items.where((item) => item.isPicked).length;
    }
    return completed;
  }

  int getTotalPicksCount() {
    int total = 0;
    for (final items in _pickItems.values) {
      total += items.length;
    }
    return total;
  }

  double getCompletionRate() {
    final total = getTotalPicksCount();
    if (total == 0) return 0.0;
    return getCompletedPicks() / total;
  }

  /// Returns locations sorted with completed locations at the bottom
  List<PickLocation> getSortedLocations() {
    final sortedLocations = List<PickLocation>.from(locations);

    // Sort locations: incomplete first, completed last
    sortedLocations.sort((a, b) {
      final aRemaining = getRemainingPicksForLocation(a.id);
      final bRemaining = getRemainingPicksForLocation(b.id);
      final aCompleted = aRemaining == 0;
      final bCompleted = bRemaining == 0;

      // If completion status is different, sort by completion (incomplete first)
      if (aCompleted != bCompleted) {
        return aCompleted ? 1 : -1;
      }

      // If both have same completion status, maintain original order
      return 0;
    });

    return sortedLocations;
  }

  List<PickItem> searchItems(String query) {
    if (query.isEmpty) return [];

    final allItems = <PickItem>[];
    for (final items in _pickItems.values) {
      allItems.addAll(items);
    }

    return allItems.where((item) {
      return item.productCode.toLowerCase().contains(query.toLowerCase()) ||
             item.title.toLowerCase().contains(query.toLowerCase()) ||
             item.location.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<PickItem> getFilteredItems({
    String? locationId,
    bool? isPicked,
    String? searchQuery,
  }) {
    List<PickItem> items;

    if (locationId != null) {
      items = _pickItems[locationId] ?? [];
    } else {
      items = [];
      for (final locationItems in _pickItems.values) {
        items.addAll(locationItems);
      }
    }

    if (isPicked != null) {
      items = items.where((item) => item.isPicked == isPicked).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item.productCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
               item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               item.location.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return items;
  }

  void markAllAsPicked(String locationId) {
    final items = _pickItems[locationId];
    if (items != null) {
      for (final item in items) {
        item.isPicked = true;
      }
      notifyListeners();
    }
  }

  void markAllAsUnpicked(String locationId) {
    final items = _pickItems[locationId];
    if (items != null) {
      for (final item in items) {
        item.isPicked = false;
      }
      notifyListeners();
    }
  }

  /// Mark all items as picked across all locations
  void markAllAsPickedGlobally() {
    for (final items in _pickItems.values) {
      for (final item in items) {
        item.isPicked = true;
      }
    }
    notifyListeners();
  }

  /// Mark all items as unpicked across all locations
  void markAllAsUnpickedGlobally() {
    for (final items in _pickItems.values) {
      for (final item in items) {
        item.isPicked = false;
      }
    }
    notifyListeners();
  }

  /// Get remaining picks count across all locations
  int getRemainingPicksGlobally() {
    int remaining = 0;
    for (final items in _pickItems.values) {
      remaining += items.where((item) => !item.isPicked).length;
    }
    return remaining;
  }

  /// Extract building name from rack location string
  /// Examples: 'C3-Front-Rack-01' -> 'C3-Front', 'C1-Rack-01' -> 'C1'
  String getBuildingNameFromLocation(String rackLocation) {
    // Handle different location formats
    if (rackLocation.startsWith('C3-Front')) return 'C3-Front';
    if (rackLocation.startsWith('C3-Back')) return 'C3-Back';
    if (rackLocation.startsWith('C3-Crocs')) return 'C3-Crocs';
    if (rackLocation.startsWith('C3-Shop')) return 'C3-Shop';
    if (rackLocation.startsWith('C1')) return 'C1';

    // Fallback: try to extract building from location string
    final parts = rackLocation.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    } else if (parts.isNotEmpty) {
      return parts[0];
    }

    return 'Unknown';
  }

  /// Get location ID from building name
  /// Used for color coding and identification
  String getLocationIdFromBuildingName(String buildingName) {
    switch (buildingName) {
      case 'C3-Front': return 'c3f';
      case 'C3-Back': return 'c3b';
      case 'C3-Crocs': return 'c3c';
      case 'C3-Shop': return 'c3s';
      case 'C1': return 'c1';
      default: return 'unknown';
    }
  }

  /// Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Helper method to clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Helper method to set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Helper method to update location pick count
  void _updateLocationPickCount(String locationId, int count) {
    final locationIndex = _locations.indexWhere((loc) => loc.id == locationId);
    if (locationIndex != -1) {
      _locations[locationIndex] = PickLocation(
        id: _locations[locationIndex].id,
        name: _locations[locationIndex].name,
        totalPicks: count,
      );
      notifyListeners();
    }
  }

  /// Helper method to update location pick count without notifying listeners
  /// Used for batch operations to prevent multiple UI rebuilds
  void _updateLocationPickCountSilent(String locationId, int count) {
    final locationIndex = _locations.indexWhere((loc) => loc.id == locationId);
    if (locationIndex != -1) {
      _locations[locationIndex] = PickLocation(
        id: _locations[locationIndex].id,
        name: _locations[locationIndex].name,
        totalPicks: count,
      );
      // Note: No notifyListeners() call here - caller is responsible for notification
    }
  }

  /// Refreshes all location pick counts from API
  Future<void> refreshLocationCounts() async {
    _setLoading(true);
    _clearError();

    try {
      final Map<String, int> counts = await GetPicksApi.getPickCountsByLocation();

      for (int i = 0; i < _locations.length; i++) {
        final locationId = _locations[i].id;
        final count = counts[locationId] ?? 0;
        _locations[i] = PickLocation(
          id: locationId,
          name: _locations[i].name,
          totalPicks: count,
        );
      }

      notifyListeners();
    } on AuthenticationException {
      // Re-throw authentication exceptions so they can be handled by the UI
      _setError('Authentication failed');
      rethrow;
    } catch (e) {
      _setError('Failed to refresh location counts: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads all picks data immediately after login
  /// This populates the location counts so users can see pick quantities right away
  /// without having to navigate to each location first
  Future<void> loadAllPicksAfterLogin() async {
    _setLoading(true);
    _clearError();

    try {
      // Get pick counts for all locations to update the dashboard
      final Map<String, int> counts = await GetPicksApi.getPickCountsByLocation();

      // Update location pick counts
      for (int i = 0; i < _locations.length; i++) {
        final locationId = _locations[i].id;
        final count = counts[locationId] ?? 0;
        _locations[i] = PickLocation(
          id: locationId,
          name: _locations[i].name,
          totalPicks: count,
        );
      }

      // Force refresh picks for all locations to ensure fresh data
      // This is critical for dashboard refresh to show updated completed/pending stats
      // Use suppressNotifications to prevent multiple UI rebuilds during batch loading
      for (final location in _locations) {
        if (location.totalPicks > 0) {
          try {
            // IMPORTANT: Use forceRefresh: true to bypass cache and get fresh data
            // Use suppressNotifications: true to prevent setState() during build exceptions
            await loadPicksForLocation(
              location.id,
              forceRefresh: true,
              suppressNotifications: true
            );
          } catch (e) {
            // Continue with other locations even if one fails
            // This prevents one failed location from blocking the entire refresh
          }
        }
      }

      // Single notifyListeners() call at the end to trigger UI rebuild once
      notifyListeners();
    } on AuthenticationException {
      // Re-throw authentication exceptions so they can be handled by the UI
      _setError('Authentication failed');
      rethrow;
    } catch (e) {
      _setError('Failed to load picks data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}
