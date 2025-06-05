/*
=======================================================================================================================================
API Service: login_pin_api
=======================================================================================================================================
Purpose: Handles authentication API calls to the login_pin endpoint
Authenticates users with PIN and returns JWT token for session management
=======================================================================================================================================
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Response model for login PIN API
class LoginPinResponse {
  final String returnCode;
  final String? token;
  final LoginUser? user;
  final String? message;

  LoginPinResponse({
    required this.returnCode,
    this.token,
    this.user,
    this.message,
  });

  factory LoginPinResponse.fromJson(Map<String, dynamic> json) {
    return LoginPinResponse(
      returnCode: json['return_code'] ?? '',
      token: json['token'],
      user: json['user'] != null ? LoginUser.fromJson(json['user']) : null,
      message: json['message'],
    );
  }

  bool get isSuccess => returnCode == 'SUCCESS';
}

/// User model for login response
class LoginUser {
  final int pin;
  final String name;

  LoginUser({
    required this.pin,
    required this.name,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      pin: json['pin'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
      'name': name,
    };
  }
}

/// API service for login PIN authentication
class LoginPinApi {
  
  /// Authenticate user with PIN
  /// 
  /// Sends PIN to server and returns authentication response
  /// with JWT token if successful
  static Future<LoginPinResponse> authenticate(int pin) async {
    try {
      // Prepare request body
      final requestBody = {
        'pin': pin,
      };

      // Make POST request to login_pin endpoint
      final response = await http.post(
        Uri.parse(AppConfig.loginPinUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(AppConfig.requestTimeout);

      // Parse response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return LoginPinResponse.fromJson(responseData);
      } else {
        // Handle HTTP error status codes
        return LoginPinResponse(
          returnCode: 'SERVER_ERROR',
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
      
    } catch (e) {
      // Handle network or parsing errors
      return LoginPinResponse(
        returnCode: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
