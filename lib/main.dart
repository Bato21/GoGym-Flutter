import 'package:flutter/material.dart';

import 'tabs/tabs_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GoGymApp());
}

class GoGymApp extends StatelessWidget {
  const GoGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      // Igual que dark.system.css en Ionic: sigue el tema del sistema.
      themeMode: ThemeMode.system,
      home: const TabsPage(),
    );
  }
}
