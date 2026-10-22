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

  /// Mueve un ejercicio de [desde] a [hasta] (índices tras quitarlo) y lo
  /// guarda. La lista cambia al instante; si falla el guardado, vuelve atrás.
  Future<void> reordenar(int rutinaId, int desde, int hasta) async {
    final indice = _rutinas.indexWhere((r) => r.id == rutinaId);
    if (indice == -1 || desde == hasta) return;
    final anterior = _rutinas[indice];
    final ejercicios = [...anterior.ejercicios];
    ejercicios.insert(hasta, ejercicios.removeAt(desde));
    _reemplazar(anterior.copyWith(ejercicios: ejercicios));
    try {
      await _repositorio.guardarEjercicios(rutinaId, ejercicios);
    } catch (_) {
      _reemplazar(anterior);
      rethrow;
    }
  }

  void _reemplazar(Rutina rutina) {
    _rutinas = [
      for (final r in _rutinas) r.id == rutina.id ? rutina : r,
    ];
    notifyListeners();
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
