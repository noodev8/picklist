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
    return _pickItems[locationId] ?? [];
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
}
