import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/login_pin_api.dart';

/// Service for handling authentication operations
class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';

  /// Authenticate user with PIN using API
  Future<bool> authenticate(String pin) async {
    try {
      // Validate PIN format (must be 4 digits)
      if (!isValidPin(pin)) {
        return false;
      }

      // Convert PIN to integer for API call
      final pinNumber = int.parse(pin);

      // Call login API
      final response = await LoginPinApi.authenticate(pinNumber);

      // Check if authentication was successful
      if (response.isSuccess && response.token != null && response.user != null) {
        final prefs = await SharedPreferences.getInstance();

        // Store JWT token and user data
        await prefs.setString(_tokenKey, response.token!);
        await prefs.setString(_userDataKey, response.user!.toJson().toString());
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if stored JWT token is valid and not expired
  /// Returns true if token exists and is valid, false otherwise
  Future<bool> hasValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final lastLoginString = prefs.getString(_lastLoginKey);

      // Check if token and login time exist
      if (token == null || lastLoginString == null) {
        return false;
      }

      // Parse the last login time
      final lastLogin = DateTime.parse(lastLoginString);
      final now = DateTime.now();

      // Check if token is within 90-day validity period
      final daysSinceLogin = now.difference(lastLogin).inDays;
      if (daysSinceLogin >= 90) {
        // Token has expired, clean up stored data
        await logout();
        return false;
      }

      // Token exists and is within validity period
      return true;
    } catch (e) {
      // If any error occurs, consider token invalid
      return false;
    }
  }

  /// Attempt automatic authentication using stored token
  /// Returns true if successfully authenticated, false otherwise
  Future<bool> tryAutoAuthenticate() async {
    try {
      // Check if we have a valid token
      if (!await hasValidToken()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Update authentication state
      await prefs.setBool(_isLoggedInKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_lastLoginKey);
    } catch (e) {
      // Handle error silently for logout
    }
  }

  /// Get last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginString = prefs.getString(_lastLoginKey);
      if (lastLoginString != null) {
        return DateTime.parse(lastLoginString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored user data
  Future<LoginUser?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        // Parse user data from stored string
        // Note: In a real app, you'd want to store this as JSON
        // For now, we'll return null and rely on token validation
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate PIN format
  bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// Get days remaining until token expires
  /// Returns null if no token or error occurs
  Future<int?> getDaysUntilTokenExpires() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginString = prefs.getString(_lastLoginKey);

      if (lastLoginString == null) {
        return null;
      }

      final lastLogin = DateTime.parse(lastLoginString);
      final now = DateTime.now();
      final daysSinceLogin = now.difference(lastLogin).inDays;
      final daysRemaining = 90 - daysSinceLogin;

      return daysRemaining > 0 ? daysRemaining : 0;
    } catch (e) {
      return null;
    }
  }

  /// Get authorization headers for API requests
  /// Returns headers with JWT token if available
  static Future<Map<String, String>> getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    } catch (e) {
      // Return basic headers if error occurs
      return {
        'Content-Type': 'application/json',
      };
    }
  }

  /// Check if API response indicates authentication failure
  /// Returns true if response contains FORBIDDEN or UNAUTHORIZED return codes
  static bool isAuthenticationError(Map<String, dynamic> response) {
    final returnCode = response['return_code'];
    return returnCode == 'FORBIDDEN' || returnCode == 'UNAUTHORIZED';
  }

  /// Handle authentication failure by clearing stored credentials
  /// This method should be called when API returns FORBIDDEN/UNAUTHORIZED
  static Future<void> handleAuthenticationFailure() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all authentication data
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_lastLoginKey);

    } catch (e) {
      // Log error but don't throw - we want to continue with logout process
      print('Error clearing authentication data: $e');
    }
  }
}
