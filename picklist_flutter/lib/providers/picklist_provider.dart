import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pick_item.dart';
import '../models/pick_location.dart';

class PicklistProvider with ChangeNotifier {
  static const String _pinKey = 'user_pin';
  static const String _defaultPin = '1234'; // Default PIN for testing
  bool _isAuthenticated = false;
  final List<PickLocation> locations = dummyLocations;
  Map<String, List<PickItem>> _pickItems = {};

  bool get isAuthenticated => _isAuthenticated;
  
  PicklistProvider() {
    _initializeData();
  }

  void _initializeData() {
    // Initialize dummy pick items for each location
    for (var location in locations) {
      _pickItems[location.id] = getDummyPickItems(location.id);
    }
  }

  Future<bool> authenticate(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    String savedPin = prefs.getString(_pinKey) ?? _defaultPin;
    _isAuthenticated = pin == savedPin;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }

  List<PickItem> getPicksForLocation(String locationId) {
    final items = _pickItems[locationId] ?? [];
    // Sort items by rack location for better picker workflow
    items.sort((a, b) => a.location.compareTo(b.location));
    return items;
  }

  void togglePickStatus(String locationId, String pickId) {
    final items = _pickItems[locationId];
    if (items != null) {
      final itemIndex = items.indexWhere((item) => item.id == pickId);
      if (itemIndex != -1) {
        items[itemIndex].isPicked = !items[itemIndex].isPicked;
        notifyListeners();
      }
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
}
