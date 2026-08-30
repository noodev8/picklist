import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/state/auth_provider.dart';
import '../../home/presentation/home_screen.dart';

/// Decides where to land: straight into the run if the stored token is still
/// good, otherwise the PIN pad.
///
/// It moves on the moment the check comes back. The previous version held the
/// screen for two seconds on purpose, which is two seconds of a picker's shift
/// every time they open the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    bool signedIn = false;
    try {
      signedIn = await context.read<AuthProvider>().tryAutoAuthenticate();
    } catch (_) {
      signedIn = false;
    }
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, Animation<double> animation, __) =>
            signedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
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
            ),
            AppSpacing.h16,
            Text(
              'PICKLIST',
              style: AppTypography.eyebrow.copyWith(letterSpacing: 4),
            ),
          ],
        ),
      ),
    );
  }
}
