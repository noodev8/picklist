/*
=======================================================================================================================================
API Service Wrapper
=======================================================================================================================================
Purpose: Centralized wrapper for API calls that handles authentication errors globally
Provides methods to execute API calls with automatic authentication error handling
=======================================================================================================================================
*/

import 'package:flutter/material.dart';
import '../utils/auth_error_handler.dart';

/// Global navigation key for handling authentication errors from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Wrapper service for API calls with centralized authentication error handling
class ApiServiceWrapper {
  
  /// Execute an API call with automatic authentication error handling
  /// 
  /// [apiCall] - The API call function to execute
  /// [context] - Optional BuildContext for navigation (if not provided, uses global navigator)
  /// [showErrorMessage] - Whether to show error message to user (default: true)
  /// Returns the result of the API call or rethrows non-authentication errors
  static Future<T> executeWithAuthHandling<T>(
    Future<T> Function() apiCall, {
    BuildContext? context,
    bool showErrorMessage = true,
  }) async {
    try {
      return await apiCall();
    } on AuthenticationException catch (authError) {
      // Handle authentication error
      final navigatorContext = context ?? navigatorKey.currentContext;
      
      if (navigatorContext != null) {
        await AuthErrorHandler.handleWithNotification(
          navigatorContext,
          authError.response,
          showMessage: showErrorMessage,
        );
      }
      
      // Re-throw the authentication error so calling code can handle it appropriately
      rethrow;
    } catch (error) {
      // Re-throw non-authentication errors
      rethrow;
    }
  }

  /// Execute an API call that returns a response map with authentication error handling
  /// 
  /// This is specifically for API calls that return Map<String, dynamic> responses
  /// [apiCall] - The API call function to execute
  /// [context] - Optional BuildContext for navigation
  /// [showErrorMessage] - Whether to show error message to user (default: true)
  /// Returns the response map or rethrows errors
  static Future<Map<String, dynamic>> executeApiCallWithResponse(
    Future<Map<String, dynamic>> Function() apiCall, {
    BuildContext? context,
    bool showErrorMessage = true,
  }) async {
    try {
      final response = await apiCall();
      
      // Check if the response indicates authentication failure
      if (AuthErrorHandler.isAuthenticationError(response)) {
        final navigatorContext = context ?? navigatorKey.currentContext;
        
        if (navigatorContext != null) {
          await AuthErrorHandler.handleWithNotification(
            navigatorContext,
            response,
            showMessage: showErrorMessage,
          );
        }
        
        // Throw authentication exception
        throw AuthenticationException(
          response['message'] ?? 'Authentication failed',
          response,
        );
      }
      
      return response;
    } catch (error) {
      // Re-throw all errors (including AuthenticationException from above)
      rethrow;
    }
  }

  /// Check if an error is an authentication error
  /// 
  /// [error] - The error to check
  /// Returns true if the error is an authentication error
  static bool isAuthenticationError(dynamic error) {
    return error is AuthenticationException;
  }

  /// Handle authentication error manually
  /// 
  /// This can be used when you need to handle authentication errors
  /// in a specific way or at a specific time
  /// [context] - BuildContext for navigation
  /// [response] - The API response that triggered the error
  /// [showMessage] - Whether to show error message to user
  static Future<void> handleAuthError(
    BuildContext context,
    Map<String, dynamic> response, {
    bool showMessage = true,
  }) async {
    await AuthErrorHandler.handleWithNotification(
      context,
      response,
      showMessage: showMessage,
    );
  }
}
