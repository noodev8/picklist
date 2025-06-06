import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/state/auth_provider.dart';
import 'providers/picklist_provider.dart';
import 'theme/app_theme.dart';
import 'core/services/api_service_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PicklistApp());
}

class PicklistApp extends StatelessWidget {
  const PicklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PicklistProvider()),
      ],
      child: MaterialApp(
        title: 'Picklist',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
