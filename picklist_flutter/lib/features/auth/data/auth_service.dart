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
}
