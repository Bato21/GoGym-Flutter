import 'package:flutter/foundation.dart';

import '../data/datos_repositorio.dart';
import '../models/registro_calorias.dart';
import '../utils/fechas.dart';

/// Comidas y actividades por día de la cuenta con sesión. Los días se piden a
/// Supabase la primera vez que se miran y quedan en memoria.
/// La meta, el peso y las metas de macros viven en el perfil.
class CaloriasProvider extends ChangeNotifier {
  CaloriasProvider(this._repositorio);

  final DatosRepositorio _repositorio;
  String? _usuarioId;
  final _registros = <DateTime, RegistroCalorias>{};

  /// El registro del día; vacío si no tiene o todavía no se carga.
  RegistroCalorias registro(DateTime fecha) {
    final dia = soloDia(fecha);
    return _registros[dia] ?? RegistroCalorias(fecha: dia);
  }

  bool cargado(DateTime fecha) => _registros.containsKey(soloDia(fecha));

  /// Al iniciar sesión: olvida lo anterior y trae el día de [hoy].
  Future<void> cargar(String usuarioId, {DateTime? hoy}) async {
    _usuarioId = usuarioId;
    _registros.clear();
    await cargarDia(hoy ?? DateTime.now());
  }

  Future<void> cargarDia(DateTime fecha) async {
    final dia = soloDia(fecha);
    final guardado = await _repositorio.registroCalorias(_idActual, dia);
    _registros[dia] = guardado ?? RegistroCalorias(fecha: dia);
    notifyListeners();
  }

  Future<void> agregarComida(DateTime fecha, Comida comida) {
    final actual = registro(fecha);
    return _guardar(actual.copyWith(comidas: [...actual.comidas, comida]));
  }

  Future<void> borrarComida(DateTime fecha, int comidaId) {
    final actual = registro(fecha);
    return _guardar(
      actual.copyWith(
        comidas: [
          for (final c in actual.comidas)
            if (c.id != comidaId) c,
        ],
      ),
    );
  }

  Future<void> agregarActividad(DateTime fecha, Actividad actividad) {
    final actual = registro(fecha);
    return _guardar(
      actual.copyWith(actividades: [...actual.actividades, actividad]),
    );
  }

  Future<void> borrarActividad(DateTime fecha, int actividadId) {
    final actual = registro(fecha);
    return _guardar(
      actual.copyWith(
        actividades: [
          for (final a in actual.actividades)
            if (a.id != actividadId) a,
        ],
      ),
    );
  }

  /// El cambio se ve al instante; si falla el guardado, vuelve atrás.
  Future<void> _guardar(RegistroCalorias nuevo) async {
    final id = _idActual;
    final anterior = _registros[nuevo.fecha];
    _registros[nuevo.fecha] = nuevo;
    notifyListeners();
    try {
      _registros[nuevo.fecha] = await _repositorio.guardarRegistroCalorias(
        id,
        nuevo,
      );
      notifyListeners();
    } catch (_) {
      if (anterior == null) {
        _registros.remove(nuevo.fecha);
      } else {
        _registros[nuevo.fecha] = anterior;
      }
      notifyListeners();
      rethrow;
    }
  }

  String get _idActual =>
      _usuarioId ?? (throw StateError('No hay una cuenta cargada.'));

  void limpiar() {
    _usuarioId = null;
    _registros.clear();
    notifyListeners();
  }
}
