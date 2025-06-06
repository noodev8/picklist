/*
=======================================================================================================================================
Authentication Error Handler Utility
=======================================================================================================================================
Purpose: Centralized handling of authentication errors from API responses
Provides methods to detect and handle FORBIDDEN/UNAUTHORIZED responses
=======================================================================================================================================
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';

/// Custom exception for authentication failures
class AuthenticationException implements Exception {
  final String message;
  final Map<String, dynamic> response;

  const AuthenticationException(this.message, this.response);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Utility class for handling authentication errors across the app
class AuthErrorHandler {
  
  /// Check if an API response indicates authentication failure
  /// 
  /// [response] - The parsed JSON response from an API call
  /// Returns true if the response indicates authentication failure
  static bool isAuthenticationError(Map<String, dynamic> response) {
    return AuthService.isAuthenticationError(response);
  }

  /// Handle authentication failure by logging out user and navigating to login
  /// 
  /// [context] - The current BuildContext for navigation
  /// [response] - The API response that triggered the authentication error
  /// Returns true if authentication error was handled, false otherwise
  static Future<bool> handleAuthenticationError(
    BuildContext context, 
    Map<String, dynamic> response
  ) async {
    // Check if this is actually an authentication error
    if (!isAuthenticationError(response)) {
      return false;
    }

    try {
      // Clear stored authentication data
      await AuthService.handleAuthenticationFailure();

      // Update auth provider state if available
      if (context.mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.logout();
      }

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false, // Remove all previous routes
        );
      }

      return true;
    } catch (e) {
      // If error handling fails, still try to navigate to login
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return true;
    }
  }

  /// Show authentication error message to user
  /// 
  /// [context] - The current BuildContext for showing snackbar
  /// [message] - Optional custom message, defaults to generic auth error message
  static void showAuthenticationErrorMessage(
    BuildContext context, 
    {String? message}
  ) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Text(
        message ?? 'Your session has expired. Please log in again.',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red[600],
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Handle authentication error with user notification
  /// 
  /// Combines error handling with user notification
  /// [context] - The current BuildContext
  /// [response] - The API response that triggered the error
  /// [showMessage] - Whether to show error message to user (default: true)
  /// Returns true if authentication error was handled
  static Future<bool> handleWithNotification(
    BuildContext context,
    Map<String, dynamic> response,
    {bool showMessage = true}
  ) async {
    if (!isAuthenticationError(response)) {
      return false;
    }

    // Show error message if requested
    if (showMessage) {
      final message = response['message'] as String?;
      showAuthenticationErrorMessage(context, message: message);
    }

    // Handle the authentication error
    return await handleAuthenticationError(context, response);
  }
}
