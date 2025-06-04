/*
=======================================================================================================================================
API Service: set_picked_api
=======================================================================================================================================
Purpose: Handles API calls to the set_picked endpoint on the server
Allows users to pick/unpick items by updating their status in the database
=======================================================================================================================================
*/

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SetPickedApi {
  
  /// Marks an item as picked (qty = 0)
  /// 
  /// [itemId] - The unique ID of the item to pick
  /// Returns true if successful, throws exception on error
  static Future<bool> pickItem(String itemId) async {
    return await _setPickedStatus(itemId, 'pick');
  }
  
  /// Marks an item as unpicked (qty = 1) 
  /// 
  /// [itemId] - The unique ID of the item to unpick
  /// Returns true if successful, throws exception on error
  static Future<bool> unpickItem(String itemId) async {
    return await _setPickedStatus(itemId, 'unpick');
  }
  
  /// Internal method to handle pick/unpick API calls
  /// 
  /// [itemId] - The unique ID of the item
  /// [action] - Either 'pick' or 'unpick'
  /// Returns true if successful, throws exception on error
  static Future<bool> _setPickedStatus(String itemId, String action) async {
    try {
      // Validate inputs
      if (itemId.isEmpty) {
        throw Exception('Item ID cannot be empty');
      }
      
      if (action != 'pick' && action != 'unpick') {
        throw Exception('Invalid action: $action. Must be "pick" or "unpick"');
      }
      
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'id': itemId,
        'action': action,
      };
      
      // Make HTTP POST request to the server
      final response = await http.post(
        Uri.parse(AppConfig.setPickedUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(AppConfig.requestTimeout);
      
      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
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
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          throw Exception('Validation Error: ${errorResponse['message'] ?? 'Invalid request'}');
        } catch (e) {
          throw Exception('Bad Request: ${response.reasonPhrase}');
        }
      } else if (response.statusCode == 404) {
        // Item not found
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
  
  /// Toggles the picked status of an item
  /// 
  /// [itemId] - The unique ID of the item
  /// [currentlyPicked] - Current picked status of the item
  /// Returns true if successful, throws exception on error
  static Future<bool> togglePickedStatus(String itemId, bool currentlyPicked) async {
    if (currentlyPicked) {
      // Item is currently picked, so unpick it
      return await unpickItem(itemId);
    } else {
      // Item is not picked, so pick it
      return await pickItem(itemId);
    }
  }
}
