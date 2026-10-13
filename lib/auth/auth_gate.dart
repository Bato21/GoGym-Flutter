import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_page.dart';
import '../tabs/tabs_page.dart';

/// Sin sesión muestra el login; con sesión, las pestañas.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});

  final GoTrueClient auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _suscripcion;
  User? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.auth.currentUser;

    // Solo reacciona si cambia la cuenta: refrescar el token no reconstruye nada.
    _suscripcion = widget.auth.onAuthStateChange.listen((estado) {
      final usuario = estado.session?.user;
      if (usuario?.id == _usuario?.id) return;
      setState(() => _usuario = usuario);
    });
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _usuario == null ? LoginPage(auth: widget.auth) : const TabsPage();
  }
}
