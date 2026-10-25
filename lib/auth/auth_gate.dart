import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_page.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/navegacion_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/rutinas_provider.dart';
import '../tabs/tabs_page.dart';

/// Sin sesión muestra el login. Con sesión carga los datos de la cuenta en los
/// providers y recién entonces muestra las pestañas: ninguna se abre a medias.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});

  final GoTrueClient auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _suscripcion;
  User? _usuario;
  Future<void>? _carga;

  @override
  void initState() {
    super.initState();
    _usuario = widget.auth.currentUser;
    if (_usuario != null) _carga = _cargar(_usuario!);

    // Solo reacciona si cambia la cuenta: refrescar el token no recarga nada.
    _suscripcion = widget.auth.onAuthStateChange.listen((estado) {
      final usuario = estado.session?.user;
      if (usuario?.id == _usuario?.id) return;
      setState(() {
        _usuario = usuario;
        if (usuario == null) {
          _limpiar();
          _carga = null;
        } else {
          _carga = _cargar(usuario);
        }
      });
    });
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }

  Future<void> _cargar(User usuario) {
    final datos = usuario.userMetadata ?? const {};
    return Future.wait([
      context.read<PerfilProvider>().cargar(
        usuario.id,
        nombre: (datos['nombre'] as String? ?? '').trim(),
        apellido: (datos['apellido'] as String? ?? '').trim(),
      ),
      context.read<RutinasProvider>().cargar(usuario.id),
      context.read<EntrenamientosProvider>().cargar(usuario.id),
    ]);
  }

  void _limpiar() {
    context.read<PerfilProvider>().limpiar();
    context.read<RutinasProvider>().limpiar();
    context.read<EntrenamientosProvider>().limpiar();
    context.read<NavegacionProvider>().irA(Pestana.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    if (usuario == null) return LoginPage(auth: widget.auth);

    return FutureBuilder<void>(
      future: _carga,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _ErrorCarga(
            onReintentar: () => setState(() => _carga = _cargar(usuario)),
            onCerrarSesion: widget.auth.signOut,
          );
        }
        return TabsPage(onCerrarSesion: widget.auth.signOut);
      },
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.onReintentar, required this.onCerrarSesion});

  final VoidCallback onReintentar;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No pudimos cargar los datos de tu cuenta. Revisa tu conexión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: onCerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
