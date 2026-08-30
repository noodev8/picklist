import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/presentation/home_screen.dart';
import '../state/auth_provider.dart';
import 'widgets/pin_pad.dart';

/// PIN entry. Signing in happens once every few months, so the screen stays out
/// of the way: a mark, four slots, and a keypad sized for a thumb.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const int _pinLength = 4;

  String _pin = '';
  bool _isChecking = false;
  String? _error;

  void _addDigit(String digit) {
    if (_isChecking || _pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _pinLength) {
      unawaited(_submit());
    }
  }

  void _backspace() {
    if (_isChecking || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _isChecking = true);

    final AuthProvider auth = context.read<AuthProvider>();
    final bool success = await auth.authenticate(_pin);
    if (!mounted) return;

    if (success) {
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, __) =>
              const HomeScreen(),
          transitionsBuilder: (_, Animation<double> animation, __,
                  Widget child,) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    setState(() {
      _isChecking = false;
      _pin = '';
      _error = auth.errorMessage.isEmpty
          ? 'That PIN is not on the list. Try again.'
          : auth.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),
              _mark(),
              AppSpacing.h24,
              Text('PICKLIST', style: AppTypography.title.copyWith(
                letterSpacing: 4,
                fontSize: 28,
              ),),
              AppSpacing.h8,
              Text(
                _isChecking ? 'Checking' : 'Enter your PIN',
                style: AppTypography.detail,
              ),
              const Spacer(),
              PinDots(
                filled: _pin.length,
                length: _pinLength,
                hasError: _error != null,
              ),
              AppSpacing.h16,
              SizedBox(
                height: 20,
                child: _error == null
                    ? null
                    : Text(
                        _error!,
                        style: AppTypography.detail.copyWith(
                          color: AppColors.alert,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              AppSpacing.h16,
              PinPad(
                onDigit: _addDigit,
                onBackspace: _backspace,
                enabled: !_isChecking,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mark() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.signal, width: 2),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.signal,
        size: 26,
      ),
    );
  }
}
