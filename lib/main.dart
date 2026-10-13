import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'config/env.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.configurado) {
    runApp(const _ConfiguracionFaltante());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  runApp(GoGymApp(home: AuthGate(auth: Supabase.instance.client.auth)));
}

class GoGymApp extends StatelessWidget {
  const GoGymApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      // Igual que dark.system.css en Ionic: sigue el tema del sistema.
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}

/// Se muestra si se compiló sin env.json: evita un error críptico de Supabase.
class _ConfiguracionFaltante extends StatelessWidget {
  const _ConfiguracionFaltante();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Falta la configuración de Supabase.\n\n'
              'Copia env.example.json a env.json, completa los valores y corre:\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
