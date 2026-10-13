import 'package:flutter/foundation.dart';

import '../data/datos_repositorio.dart';
import '../models/perfil.dart';

/// Perfil de la cuenta con sesión. Inicio, Perfil y Calorías leen de aquí.
class PerfilProvider extends ChangeNotifier {
  PerfilProvider(this._repositorio);

  final DatosRepositorio _repositorio;
  String? _usuarioId;
  Perfil? _perfil;

  /// null hasta que se carga la cuenta.
  Perfil? get perfil => _perfil;

  /// Trae el perfil; si la cuenta es nueva lo crea con el nombre que se dio
  /// al registrarse.
  Future<void> cargar(
    String usuarioId, {
    String nombre = '',
    String apellido = '',
  }) async {
    _perfil = await _repositorio.perfil(usuarioId) ??
        await _repositorio.crearPerfil(usuarioId,
            nombre: nombre, apellido: apellido);
    _usuarioId = usuarioId;
    notifyListeners();
  }

  Future<void> recargar() async {
    final id = _usuarioId;
    if (id != null) await cargar(id);
  }

  void limpiar() {
    _usuarioId = null;
    _perfil = null;
    notifyListeners();
  }
}
