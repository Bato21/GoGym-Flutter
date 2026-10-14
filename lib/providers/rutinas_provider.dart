import 'package:flutter/foundation.dart';

import '../data/datos_repositorio.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';

/// Rutinas de la cuenta con sesión.
class RutinasProvider extends ChangeNotifier {
  RutinasProvider(this._repositorio);

  final DatosRepositorio _repositorio;
  String? _usuarioId;
  List<Rutina> _rutinas = const [];

  List<Rutina> get rutinas => List.unmodifiable(_rutinas);

  /// Las que se pueden empezar: con al menos un ejercicio.
  List<Rutina> get disponibles =>
      _rutinas.where((r) => r.ejercicios.isNotEmpty).toList();

  /// Rotación: la rutina que sigue a la última entrenada según [historial]
  /// (más reciente primero). Sin historial, la primera. null si no hay rutinas.
  Rutina? siguiente(List<Sesion> historial) {
    final lista = disponibles;
    if (lista.isEmpty) return null;
    for (final sesion in historial) {
      final indice = lista.indexWhere((r) => r.id == sesion.rutinaId);
      if (indice != -1) return lista[(indice + 1) % lista.length];
    }
    return lista.first;
  }

  Future<void> cargar(String usuarioId) async {
    _rutinas = await _repositorio.rutinas(usuarioId);
    _usuarioId = usuarioId;
    notifyListeners();
  }

  Future<void> recargar() async {
    final id = _usuarioId;
    if (id != null) await cargar(id);
  }

  void limpiar() {
    _usuarioId = null;
    _rutinas = const [];
    notifyListeners();
  }
}
