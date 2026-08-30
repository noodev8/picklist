import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/api_service_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'providers/picklist_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  runApp(const PicklistApp());
}

class PicklistApp extends StatelessWidget {
  const PicklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<PicklistProvider>(
          create: (_) => PicklistProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Picklist',
        theme: AppTheme.theme,
        home: const SplashScreen(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
