import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Modo { entrar, registrar }

/// Mínimo de Supabase Auth por defecto.
const _largoMinimoPassword = 6;

/// Inicio de sesión y registro con correo y contraseña (Supabase Auth).
/// Al entrar no navega: AuthGate escucha el cambio de sesión y muestra la app.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final GoTrueClient auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();

  _Modo _modo = _Modo.entrar;
  bool _cargando = false;
  bool _verPassword = false;
  String? _error;
  String? _aviso;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  void _cambiarModo(_Modo modo) => setState(() {
        _modo = modo;
        _error = null;
        _aviso = null;
      });

  Future<void> _enviar() async {
    if (_cargando || !_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });
    final email = _email.text.trim();
    try {
      if (_modo == _Modo.entrar) {
        await widget.auth
            .signInWithPassword(email: email, password: _password.text);
        return;
      }
      final respuesta = await widget.auth.signUp(
        email: email,
        password: _password.text,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
        data: {'nombre': _nombre.text.trim(), 'apellido': _apellido.text.trim()},
      );
      // Con confirmación de correo activa, Supabase no revela si el correo ya
      // existía: devuelve un usuario sin identidades en vez de un error.
      if (respuesta.user != null &&
          (respuesta.user!.identities?.isEmpty ?? false)) {
        throw const AuthException('', code: 'user_already_exists');
      }
      if (respuesta.session == null && mounted) {
        _password.clear();
        setState(() {
          _modo = _Modo.entrar;
          _aviso = 'Te enviamos un correo a $email. '
              'Confírmalo y luego inicia sesión.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _mensajeError(e));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final registrando = _modo == _Modo.registrar;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.fitness_center, size: 48, color: colores.primary),
                    const SizedBox(height: 8),
                    Text('Go Gym',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'Tus rutinas y entrenamientos, guardados en tu cuenta.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: colores.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<_Modo>(
                      segments: const [
                        ButtonSegment(
                            value: _Modo.entrar, label: Text('Iniciar sesión')),
                        ButtonSegment(
                            value: _Modo.registrar, label: Text('Crear cuenta')),
                      ],
                      selected: {_modo},
                      onSelectionChanged: (s) => _cambiarModo(s.first),
                    ),
                    const SizedBox(height: 16),
                    if (registrando) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombre,
                              decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder()),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Escribe tu nombre.'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _apellido,
                              decoration: const InputDecoration(
                                  labelText: 'Apellido',
                                  border: OutlineInputBorder()),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                          labelText: 'Correo', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) =>
                          RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim())
                              ? null
                              : 'Escribe un correo válido.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_verPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        helperText: registrando
                            ? 'Mínimo $_largoMinimoPassword caracteres'
                            : null,
                        suffixIcon: IconButton(
                          tooltip: _verPassword
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(_verPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                      autofillHints: [
                        registrando
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _enviar(),
                      validator: (v) => (v ?? '').length < _largoMinimoPassword
                          ? 'La contraseña debe tener al menos '
                              '$_largoMinimoPassword caracteres.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: colores.error)),
                    ],
                    if (_aviso != null) ...[
                      const SizedBox(height: 12),
                      Text(_aviso!, style: TextStyle(color: colores.primary)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _cargando ? null : _enviar,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(registrando ? 'Crear cuenta' : 'Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _mensajeError(AuthException error) {
  switch (error.code) {
    case 'invalid_credentials':
      return 'Correo o contraseña incorrectos.';
    case 'email_not_confirmed':
      return 'Confirma tu correo antes de entrar (revisa tu bandeja de entrada).';
    case 'user_already_exists':
    case 'email_exists':
      return 'Ya existe una cuenta con ese correo.';
    case 'weak_password':
      return 'La contraseña es muy débil: usa al menos '
          '$_largoMinimoPassword caracteres.';
    case 'validation_failed':
      return 'Revisa el correo y la contraseña.';
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Demasiados intentos. Espera unos minutos.';
    default:
      return error.message.isNotEmpty
          ? error.message
          : 'No se pudo conectar. Revisa tu conexión.';
  }
}
