import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import '../models/ejercicio_catalogo.dart';

/// Acceso a los datos de la cuenta. Los providers dependen de esta interfaz y no
/// de Supabase, así las pruebas usan un repositorio falso.
abstract class DatosRepositorio {
  /// null si la cuenta todavía no tiene perfil.
  Future<Perfil?> perfil(String usuarioId);

  /// catalogo de ejercicios, para mostrar en la pantalla de búsqueda y en la rutina.
  Future<List<EjercicioCatalogo>> catalogoEjercicios();

  /// Crea el perfil de una cuenta nueva; el resto de columnas usa los valores
  /// por defecto de la tabla.
  Future<Perfil> crearPerfil(
    String usuarioId, {
    required String nombre,
    required String apellido,
  });

  /// Guarda los datos editables del perfil y devuelve la fila actualizada.
  Future<Perfil> actualizarPerfil(String usuarioId, Perfil perfil);

  /// Rutinas en orden de creación.
  Future<List<Rutina>> rutinas(String usuarioId);

  /// Entrenamientos terminados, el más reciente primero.
  Future<List<Sesion>> sesiones(String usuarioId);
}

/// Tablas `perfiles`, `rutinas` y `sesiones` del proyecto Supabase compartido
/// con la app de Ionic (ver supabase/migrations en Bato21/Go-Gym). RLS ya
/// limita cada consulta a la cuenta con sesión; el filtro por user_id es para
/// que Postgres use el índice.
class SupabaseDatosRepositorio implements DatosRepositorio {
  SupabaseDatosRepositorio(this._db);

  final SupabaseClient _db;

  @override
  Future<Perfil?> perfil(String usuarioId) async {
    final fila =
        await _db.from('perfiles').select().eq('id', usuarioId).maybeSingle();
    return fila == null ? null : Perfil.fromFila(fila);
  }

  @override
  Future<Perfil> crearPerfil(
    String usuarioId, {
    required String nombre,
    required String apellido,
  }) async {
    final fila = await _db
        .from('perfiles')
        .upsert({'id': usuarioId, 'nombre': nombre, 'apellido': apellido})
        .select()
        .single();
    return Perfil.fromFila(fila);
  }

  @override
  Future<Perfil> actualizarPerfil(String usuarioId, Perfil perfil) async {
    final fila = await _db
        .from('perfiles')
        .update(perfil.toUpdate())
        .eq('id', usuarioId)
        .select()
        .single();
    return Perfil.fromFila(fila);
  }

  @override
  Future<List<Rutina>> rutinas(String usuarioId) async {
    final filas =
        await _db.from('rutinas').select().eq('user_id', usuarioId).order('id');
    return filas.map(Rutina.fromFila).toList();
  }

  @override
  Future<List<Sesion>> sesiones(String usuarioId) async {
    final filas = await _db
        .from('sesiones')
        .select()
        .eq('user_id', usuarioId)
        .order('inicio', ascending: false);
    return filas.map(Sesion.fromFila).toList();
  }

  @override
  Future<List<EjercicioCatalogo>> catalogoEjercicios() async {
    final filas = await _db.from('ejercicios').select().order('nombre');
    return filas.map(EjercicioCatalogo.fromFila).toList();
  }
}
