import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/picklist_provider.dart';
import '../theme/app_theme.dart';
import 'location_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_pinController.text.length != 4) {
      setState(() {
        _errorMessage = 'PIN must be 4 digits';
      });
      return;
    }

    final provider = Provider.of<PicklistProvider>(context, listen: false);
    final success = await provider.authenticate(_pinController.text);

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LocationListScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/picklist_logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 48),
                // PIN Input
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: 'Enter PIN',
                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineLarge,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    obscureText: true,
                    onChanged: (_) => setState(() => _errorMessage = ''),
                    onSubmitted: (_) => _authenticate(),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
