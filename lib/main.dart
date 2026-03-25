import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/mobile/mobile_landing_screen.dart';
import 'screens/wearos/wearos_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock entire app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProminderApp());
}

class ProminderApp extends StatelessWidget {
  const ProminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prominder',
      theme: AppTheme.lightTheme,
      home: const ResponsiveScreenLayer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveScreenLayer extends StatelessWidget {
  const ResponsiveScreenLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // A typical Wear OS watch width is rarely larger than 300px
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 300) {
      return const WearOsHomeScreen(); // Render the minimal watch UI
    } else {
      return const MobileLandingScreen(); // Render the full mobile UI
    }
  }
}
