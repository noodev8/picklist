import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling authentication operations
class AuthService {
  static const String _pinKey = 'user_pin';
  static const String _defaultPin = '1234'; // Default PIN for testing
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';

  /// Authenticate user with PIN
  Future<bool> authenticate(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString(_pinKey) ?? _defaultPin;
      
      if (pin == savedPin) {
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

  /// Change PIN (for future use)
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString(_pinKey) ?? _defaultPin;
      
      if (currentPin == savedPin) {
        await prefs.setString(_pinKey, newPin);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate PIN format
  bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }
}
