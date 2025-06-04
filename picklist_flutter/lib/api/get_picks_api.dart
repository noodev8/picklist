/*
=======================================================================================================================================
API Service: get_picks_api
=======================================================================================================================================
Purpose: Handles API calls to the get_picks endpoint on the server
Fetches real pick data from the PostgreSQL database via the Node.js/Express server
=======================================================================================================================================
*/

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/pick_item.dart';

class GetPicksApi {
  
  /// Fetches all available picks from the server
  ///
  /// [locationFilter] - Optional filter to get picks for specific location
  /// Returns a list of PickItem objects or throws an exception on error
  static Future<List<PickItem>> getAllPicks({String? locationFilter}) async {
    try {
      print('🔍 DEBUG: Starting getAllPicks API call');
      print('🔍 DEBUG: Location filter: $locationFilter');
      print('🔍 DEBUG: API URL: ${AppConfig.getPicksUrl}');

      // Prepare request body
      final Map<String, dynamic> requestBody = {};

      // Add location filter if provided
      if (locationFilter != null && locationFilter.isNotEmpty) {
        requestBody['location_filter'] = locationFilter;
      }

      print('🔍 DEBUG: Request body: ${json.encode(requestBody)}');

      // Make HTTP POST request to the server
      final response = await http.post(
        Uri.parse(AppConfig.getPicksUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(AppConfig.requestTimeout);

      print('🔍 DEBUG: Response status code: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');
      
      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        print('🔍 DEBUG: Parsed JSON response: $jsonResponse');
        print('🔍 DEBUG: Return code: ${jsonResponse['return_code']}');

        // Check if the API returned success
        if (jsonResponse['return_code'] == 'SUCCESS') {
          // Extract picks array from response
          final List<dynamic> picksJson = jsonResponse['picks'] ?? [];

          print('🔍 DEBUG: Raw picks array length: ${picksJson.length}');
          print('🔍 DEBUG: First few picks: ${picksJson.take(2).toList()}');

          // Convert JSON picks to PickItem objects
          final List<PickItem> picks = picksJson.map((pickJson) {
            print('🔍 DEBUG: Converting pick: $pickJson');
            return PickItem.fromApiResponse(pickJson);
          }).toList();

          print('🔍 DEBUG: Converted ${picks.length} picks successfully');
          return picks;
        } else {
          // API returned an error
          throw Exception('API Error: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else {
        // HTTP error
        throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
      
    } on SocketException {
      // Network connection error
      throw Exception('Network Error: Unable to connect to server. Please check your connection.');
    } on http.ClientException {
      // HTTP client error
      throw Exception('Connection Error: Failed to connect to server.');
    } on FormatException {
      // JSON parsing error
      throw Exception('Data Error: Invalid response format from server.');
    } catch (e) {
      // Any other error
      throw Exception('Unexpected Error: ${e.toString()}');
    }
  }
  
  /// Fetches picks for a specific location
  /// 
  /// [locationId] - The location ID (e.g., 'c3f', 'c3b', etc.)
  /// Returns a list of PickItem objects for that location
  static Future<List<PickItem>> getPicksForLocation(String locationId) async {
    // Get the location filter string from config
    final String? locationFilter = AppConfig.getLocationFilter(locationId);
    
    if (locationFilter == null) {
      throw Exception('Invalid location ID: $locationId');
    }
    
    // Call the main API method with location filter
    return await getAllPicks(locationFilter: locationFilter);
  }
  
  /// Gets a summary of pick counts by location
  /// 
  /// Returns a map with location IDs as keys and pick counts as values
  static Future<Map<String, int>> getPickCountsByLocation() async {
    try {
      // Get all picks without filter
      final List<PickItem> allPicks = await getAllPicks();
      
      // Count picks by location
      final Map<String, int> locationCounts = {};
      
      // Initialize all locations with 0 counts
      for (String locationId in AppConfig.locationFilters.keys) {
        locationCounts[locationId] = 0;
      }
      
      // Count picks for each location
      for (PickItem pick in allPicks) {
        // Find which location this pick belongs to based on location string
        for (String locationId in AppConfig.locationFilters.keys) {
          final String? locationFilter = AppConfig.getLocationFilter(locationId);
          if (locationFilter != null && 
              pick.location.toLowerCase().contains(locationFilter.toLowerCase())) {
            locationCounts[locationId] = (locationCounts[locationId] ?? 0) + 1;
            break; // Only count in first matching location
          }
        }
      }
      
      return locationCounts;
    } catch (e) {
      // Return empty counts on error
      final Map<String, int> emptyCounts = {};
      for (String locationId in AppConfig.locationFilters.keys) {
        emptyCounts[locationId] = 0;
      }
      return emptyCounts;
    }
  }
}
