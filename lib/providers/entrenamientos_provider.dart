import 'package:flutter/foundation.dart';

import '../data/datos_repositorio.dart';
import '../models/sesion.dart';
import '../utils/fechas.dart';

/// Historial de entrenamientos terminados de la cuenta con sesión, y lo que se
/// calcula a partir de él: racha, totales de la semana, últimas sesiones.
/// Compartido entre Inicio, Registrar entrenamiento y Perfil.
class EntrenamientosProvider extends ChangeNotifier {
  EntrenamientosProvider(this._repositorio);

  final DatosRepositorio _repositorio;
  String? _usuarioId;
  List<Sesion> _historial = const [];

  /// Días (a medianoche) con al menos un entrenamiento.
  Set<DateTime> _diasEntrenados = const {};

  /// Entrenamientos terminados, el más reciente primero.
  List<Sesion> get historial => List.unmodifiable(_historial);

  List<Sesion> ultimas(int cantidad) => _historial.take(cantidad).toList();

  bool entrenoEl(DateTime fecha) => _diasEntrenados.contains(soloDia(fecha));

  /// Días seguidos entrenando. Si hoy aún no entrena, la racha de ayer sigue viva.
  int rachaActual(DateTime hoy) {
    var cursor = entrenoEl(hoy) ? soloDia(hoy) : sumarDias(hoy, -1);
    var racha = 0;
    while (entrenoEl(cursor)) {
      racha++;
      cursor = sumarDias(cursor, -1);
    }
    return racha;
  }

  /// La racha más larga de días seguidos entrenando.
  int get rachaRecord {
    final dias = _diasEntrenados.toList()..sort();
    var record = 0;
    var actual = 0;
    DateTime? anterior;
    for (final dia in dias) {
      actual = anterior != null && sumarDias(anterior, 1) == dia ? actual + 1 : 1;
      if (actual > record) record = actual;
      anterior = dia;
    }
    return record;
  }

  /// Entrenamientos de la semana (lunes a domingo) de [fecha].
  List<Sesion> deLaSemana(DateTime fecha) {
    final desde = inicioSemana(fecha);
    final hasta = sumarDias(desde, 7);
    return _historial
        .where((s) => !s.inicio.isBefore(desde) && s.inicio.isBefore(hasta))
        .toList();
  }

  /// Para cada día de la semana de [fecha] (0 = lunes), si hubo entrenamiento.
  List<bool> diasDeLaSemana(DateTime fecha) {
    final lunes = inicioSemana(fecha);
    return List.generate(7, (i) => entrenoEl(sumarDias(lunes, i)));
  }

  Future<void> cargar(String usuarioId) async {
    final sesiones = await _repositorio.sesiones(usuarioId);
    _usuarioId = usuarioId;
    _asignar(sesiones);
  }

  // Toda escritura pasa por aquí: se guarda en Supabase y, si sale bien, se
  // actualiza la lista y se avisa a Inicio, Logros, Perfil y Calorías.

  Future<void> agregar(Sesion sesion) async {
    final creada = await _repositorio.crearSesion(_idActual, sesion);
    _asignar([creada, ..._historial]);
  }

  Future<void> editar(Sesion sesion) async {
    final guardada = await _repositorio.actualizarSesion(_idActual, sesion);
    _asignar([for (final s in _historial) s.id == sesion.id ? guardada : s]);
  }

  /// Sale de la lista al instante (así el gesto de deslizar no espera a la
  /// red); si falla el borrado, vuelve a su lugar.
  Future<void> borrar(int sesionId) async {
    final id = _idActual;
    final anterior = _historial;
    _asignar([
      for (final s in _historial)
        if (s.id != sesionId) s,
    ]);
    try {
      await _repositorio.borrarSesion(id, sesionId);
    } catch (_) {
      _asignar(anterior);
      rethrow;
    }
  }

  String get _idActual =>
      _usuarioId ?? (throw StateError('No hay una cuenta cargada.'));

  /// Ordena (más reciente primero), recalcula los días y avisa.
  void _asignar(List<Sesion> sesiones) {
    _historial = [...sesiones]..sort((a, b) => b.inicio.compareTo(a.inicio));
    _diasEntrenados = {for (final s in _historial) soloDia(s.inicio)};
    notifyListeners();
  }

  Future<void> recargar() async {
    final id = _usuarioId;
    if (id != null) await cargar(id);
  }

  void limpiar() {
    _usuarioId = null;
    _historial = const [];
    _diasEntrenados = const {};
    notifyListeners();
  }
}
