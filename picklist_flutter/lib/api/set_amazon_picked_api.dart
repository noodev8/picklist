/*
=======================================================================================================================================
API Service: set_amazon_picked_api
=======================================================================================================================================
Purpose: Handles API calls to the set_amazon_picked endpoint on the server
Amazon picking is a move, not a quantity change: picking an item relocates it to the C3-Amazon
staging area, which is what takes it off the Amazon pick list. Unpicking puts it back at the
location it was picked from, so the caller has to supply that location - the server does not
remember it. Customer picks use set_picked_api instead.
=======================================================================================================================================
*/

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/utils/auth_error_handler.dart';
import '../features/auth/data/auth_service.dart';

class SetAmazonPickedApi {

  /// Picks an Amazon item by moving it to the staging area
  ///
  /// [itemId] - The unique ID of the item to pick
  /// Returns true if successful, throws exception on error
  static Future<bool> pickItem(String itemId) async {
    return await _setPickedStatus(itemId, 'pick');
  }

  /// Unpicks an Amazon item by moving it back where it came from
  ///
  /// [itemId] - The unique ID of the item to unpick
  /// [originalLocation] - The location the item was picked from
  /// Returns true if successful, throws exception on error
  static Future<bool> unpickItem(String itemId, String originalLocation) async {
    return await _setPickedStatus(itemId, 'unpick', originalLocation: originalLocation);
  }

  /// Toggles the picked status of an Amazon item
  ///
  /// [itemId] - The unique ID of the item
  /// [currentlyPicked] - Current picked status of the item
  /// [originalLocation] - The location the item is picked from, needed to undo a pick
  /// Returns true if successful, throws exception on error
  static Future<bool> togglePickedStatus(
    String itemId,
    bool currentlyPicked,
    String originalLocation,
  ) async {
    if (currentlyPicked) {
      return await unpickItem(itemId, originalLocation);
    } else {
      return await pickItem(itemId);
    }
  }

  /// Internal method to handle pick/unpick API calls
  ///
  /// [itemId] - The unique ID of the item
  /// [action] - Either 'pick' or 'unpick'
  /// [originalLocation] - Required for 'unpick', ignored for 'pick'
  /// Returns true if successful, throws exception on error
  static Future<bool> _setPickedStatus(
    String itemId,
    String action, {
    String? originalLocation,
  }) async {
    try {
      // Validate inputs
      if (itemId.isEmpty) {
        throw Exception('Item ID cannot be empty');
      }

      if (action != 'pick' && action != 'unpick') {
        throw Exception('Invalid action: $action. Must be "pick" or "unpick"');
      }

      // An unpick has nowhere to put the item back without this
      if (action == 'unpick' && (originalLocation == null || originalLocation.isEmpty)) {
        throw Exception('Original location is required to unpick an Amazon item');
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'id': itemId,
        'action': action,
      };

      if (action == 'unpick') {
        requestBody['original_location'] = originalLocation;
      }

      // Get authentication headers
      final headers = await AuthService.getAuthHeaders();

      // Make HTTP POST request to the server
      final response = await http.post(
        Uri.parse(AppConfig.setAmazonPickedUrl),
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
          return true;
        } else {
          // API returned an error
          throw Exception('API Error: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 400) {
        // Bad request - parse error message
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body) as Map<String, dynamic>;
          throw Exception('Validation Error: ${errorResponse['message'] ?? 'Invalid request'}');
        } catch (e) {
          throw Exception('Bad Request: ${response.reasonPhrase}');
        }
      } else if (response.statusCode == 404) {
        // Item not found or not Amazon allocated stock
        throw Exception('Item not found or not available for ${action}ing');
      } else {
        // Other HTTP error
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
      // Re-throw our custom exceptions, wrap others
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      } else {
        throw Exception('Unexpected Error: ${e.toString()}');
      }
    }
  }
}
