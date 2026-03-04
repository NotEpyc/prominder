import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/mobile/mobile_home_screen.dart';
import 'screens/wearos/wearos_home_screen.dart';

void main() {
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
      return const MobileHomeScreen(); // Render the full mobile UI
    }
  }
}
