/*
=======================================================================================================================================
Test Authentication Error Handling Screen
=======================================================================================================================================
Purpose: Simple test screen to verify authentication error handling works correctly
This is a temporary file for testing purposes only
=======================================================================================================================================
*/

import 'package:flutter/material.dart';
import 'core/utils/auth_error_handler.dart';
import 'api/get_picks_api.dart';

/// Test screen to verify authentication error handling
class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testGetPicks() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing get_picks API...';
    });

    try {
      final picks = await GetPicksApi.getAllPicks();
      setState(() {
        _status = 'Success! Got ${picks.length} picks';
      });
    } on AuthenticationException catch (authError) {
      setState(() {
        _status = 'Authentication error caught: ${authError.message}';
      });
      
      // Handle authentication error
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(
          context,
          authError.response,
          showMessage: true,
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Other error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testAuthErrorResponse() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing manual auth error...';
    });

    // Simulate an authentication error response
    final mockAuthErrorResponse = {
      'return_code': 'FORBIDDEN',
      'message': 'Invalid or expired token'
    };

    try {
      // Check if this would be detected as auth error
      if (AuthErrorHandler.isAuthenticationError(mockAuthErrorResponse)) {
        setState(() {
          _status = 'Auth error detected, handling...';
        });
        
        await AuthErrorHandler.handleWithNotification(
          context,
          mockAuthErrorResponse,
          showMessage: true,
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error in test: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Auth Error Handling'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetPicks,
              child: const Text('Test Real API Call'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthErrorResponse,
              child: const Text('Test Manual Auth Error'),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. "Test Real API Call" - Makes actual API call to get_picks\n'
                      '2. "Test Manual Auth Error" - Simulates auth error response\n'
                      '3. Both should redirect to login if auth fails\n'
                      '4. Check that error messages are shown',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
