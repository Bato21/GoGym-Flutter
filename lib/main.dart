import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'config/env.dart';
import 'data/datos_repositorio.dart';
import 'providers/entrenamientos_provider.dart';
import 'providers/navegacion_provider.dart';
import 'providers/perfil_provider.dart';
import 'providers/rutinas_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  if (!Env.configurado) {
    runApp(const _ConfiguracionFaltante());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  final cliente = Supabase.instance.client;
  runApp(GoGymApp(
    repositorio: SupabaseDatosRepositorio(cliente),
    home: AuthGate(auth: cliente.auth),
  ));
}

/// Registra los providers compartidos sobre toda la app.
class GoGymApp extends StatelessWidget {
  const GoGymApp({super.key, required this.repositorio, required this.home});

  final DatosRepositorio repositorio;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatosRepositorio>.value(value: repositorio),
        ChangeNotifierProvider(create: (_) => PerfilProvider(repositorio)),
        ChangeNotifierProvider(create: (_) => RutinasProvider(repositorio)),
        ChangeNotifierProvider(
            create: (_) => EntrenamientosProvider(repositorio)),
        ChangeNotifierProvider(create: (_) => NavegacionProvider()),
      ],
      child: MaterialApp(
        title: 'Go Gym',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        darkTheme: AppTheme.oscuro,
        // Igual que dark.system.css en Ionic: sigue el tema del sistema.
        themeMode: ThemeMode.system,
        home: home,
      ),
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
