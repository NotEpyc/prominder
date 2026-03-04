import 'package:flutter/material.dart';

class WearOsHomeScreen extends StatelessWidget {
  const WearOsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors
              .black, // WearOS often uses true black backgrounds to save battery on OLEDs
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Prominder',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('Tasks')),
          ],
        ),
      ),
    );
  }
}
