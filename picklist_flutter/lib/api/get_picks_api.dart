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
import '../core/utils/auth_error_handler.dart';
import '../features/auth/data/auth_service.dart';
import '../models/pick_item.dart';
import '../models/pick_mode.dart';

class GetPicksApi {
  
  /// Fetches all available picks from the server
  ///
  /// [locationFilter] - Optional filter to get picks for specific location
  /// [mode] - Which picking job to list (customer orders or Amazon stock)
  /// Returns a list of PickItem objects or throws an exception on error
  /// Throws AuthenticationException if authentication fails
  static Future<List<PickItem>> getAllPicks({
    String? locationFilter,
    PickMode mode = PickMode.customer,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'pick_type': mode.apiValue,
      };

      // Add location filter if provided
      if (locationFilter != null && locationFilter.isNotEmpty) {
        requestBody['location_filter'] = locationFilter;
      }

      // Get authentication headers
      final headers = await AuthService.getAuthHeaders();

      // Make HTTP POST request to the server
      final response = await http.post(
        Uri.parse(AppConfig.getPicksUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(AppConfig.requestTimeout);

      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        // Check for authentication errors first
        if (AuthErrorHandler.isAuthenticationError(jsonResponse)) {
          throw AuthenticationException(
            jsonResponse['message'] as String? ?? 'Authentication failed',
            jsonResponse,
          );
        }

        // Check if the API returned success
        if (jsonResponse['return_code'] == 'SUCCESS') {
          // Make sure we got the list we asked for. A server predating Amazon picks
          // ignores pick_type and answers with customer picks regardless, which would
          // otherwise show customer orders labelled as an Amazon job.
          final String returnedType = jsonResponse['pick_type']?.toString() ?? '';
          if (returnedType != mode.apiValue) {
            throw Exception(
              'Server does not support ${mode.displayName} picks. It needs updating.',
            );
          }

          // Extract picks array from response
          final List<dynamic> picksJson = jsonResponse['picks'] as List<dynamic>? ?? <dynamic>[];

          // Convert JSON picks to PickItem objects
          final List<PickItem> picks = picksJson.map((pickJson) {
            return PickItem.fromApiResponse(
              pickJson as Map<String, dynamic>,
              mode: mode,
            );
          }).toList();

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
}
