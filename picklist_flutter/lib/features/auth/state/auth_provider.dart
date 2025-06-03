import 'package:flutter/foundation.dart';
import '../data/auth_service.dart';

/// Provider for managing authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _lastLoginTime;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  DateTime? get lastLoginTime => _lastLoginTime;

  /// Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _isAuthenticated = await _authService.isLoggedIn();
      _lastLoginTime = await _authService.getLastLoginTime();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate user with PIN
  Future<bool> authenticate(String pin) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate PIN format
      if (!_authService.isValidPin(pin)) {
        _setError('PIN must be 4 digits');
        return false;
      }

      // Attempt authentication
      final success = await _authService.authenticate(pin);
      
      if (success) {
        _isAuthenticated = true;
        _lastLoginTime = DateTime.now();
        _clearError();
      } else {
        _setError('Invalid PIN');
      }

      return success;
    } catch (e) {
      _setError('Authentication failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _lastLoginTime = null;
      _clearError();
    } catch (e) {
      _setError('Logout failed');
    } finally {
      _setLoading(false);
    }
  }

  /// Change user PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate new PIN format
      if (!_authService.isValidPin(newPin)) {
        _setError('New PIN must be 4 digits');
        return false;
      }

      final success = await _authService.changePin(currentPin, newPin);
      
      if (!success) {
        _setError('Current PIN is incorrect');
      }

      return success;
    } catch (e) {
      _setError('Failed to change PIN');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
