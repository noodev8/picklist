/*
=======================================================================================================================================
App Configuration
=======================================================================================================================================
Purpose: Central configuration file for the picklist Flutter application
Contains API endpoints, server URLs, and other app-wide configuration settings
=======================================================================================================================================
*/

class AppConfig {
  // API Configuration
  // static const String baseUrl = 'http://192.168.1.182:3000';
  // static const String apiBaseUrl = 'http://77.68.13.150:3007'; // Test Server
  static const String apiBaseUrl = 'https://picklist.noodev8.com'; // Prod Server

  // App Settings
  static const String appName = 'Pick List';
  static const String appVersion = '1.0.1';
 
  // API Endpoints
  static const String getPicksEndpoint = '/get_picks';
  static const String setPickedEndpoint = '/set_picked';
  static const String loginPinEndpoint = '/login_pin';

  // Full API URLs
  static String get getPicksUrl => '$apiBaseUrl$getPicksEndpoint';
  static String get setPickedUrl => '$apiBaseUrl$setPickedEndpoint';
  static String get loginPinUrl => '$apiBaseUrl$loginPinEndpoint';

  // Request timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Location mapping for filtering API calls
  // Maps UI location IDs to API filter strings
  static const Map<String, String> locationFilters = {
    'c3f': 'C3-Front',
    'c3b': 'C3-Back', 
    'c3c': 'C3-Crocs',
    'c3s': 'C3-Shop',
    'c1': 'C1',
  };
  
  // Location display names
  static const Map<String, String> locationNames = {
    'c3f': 'C3-Front',
    'c3b': 'C3-Back',
    'c3c': 'C3-Crocs', 
    'c3s': 'C3-Shop',
    'c1': 'C1',
  };
  
  // Get location filter string for API calls
  static String? getLocationFilter(String locationId) {
    return locationFilters[locationId];
  }
  
  // Get location display name
  static String getLocationName(String locationId) {
    return locationNames[locationId] ?? locationId;
  }
}
