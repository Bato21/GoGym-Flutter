import 'package:go_gym/data/datos_repositorio.dart';
import 'package:go_gym/models/perfil.dart';
import 'package:go_gym/models/registro_calorias.dart';
import 'package:go_gym/models/rutina.dart';
import 'package:go_gym/models/sesion.dart';
import 'package:go_gym/models/ejercicio_catalogo.dart';

/// Repositorio en memoria para las pruebas.
class RepositorioFalso implements DatosRepositorio {
  RepositorioFalso({
    this.perfilGuardado,
    this.rutinasGuardadas = const [],
    this.sesionesGuardadas = const [],
    this.catalogoGuardado = const [],
  });

  Perfil? perfilGuardado;
  final List<Rutina> rutinasGuardadas;

  /// Cambia con crearSesion, actualizarSesion y borrarSesion.
  List<Sesion> sesionesGuardadas;
  List<EjercicioCatalogo> catalogoGuardado;

  @override
  Future<Perfil?> perfil(String usuarioId) async => perfilGuardado;

  @override
  Future<Perfil> crearPerfil(
    String usuarioId, {
    required String nombre,
    required String apellido,
  }) async => perfilGuardado = Perfil(
    nombre: nombre,
    apellido: apellido,
    objetivo: '',
    pesoKg: 75,
    diasEntrenamiento: const [0, 2, 4],
    horaEntrenamiento: '18:00',
    metaCalorias: 2200,
  );

  @override
  Future<Perfil> actualizarPerfil(String usuarioId, Perfil perfil) async =>
      perfilGuardado = perfil;

  @override
  Future<List<Rutina>> rutinas(String usuarioId) async => rutinasGuardadas;

  /// Ejercicios guardados con [guardarEjercicios], por id de rutina.
  final ejerciciosGuardados = <int, List<Ejercicio>>{};

  @override
  Future<Rutina> guardarEjercicios(
    int rutinaId,
    List<Ejercicio> ejercicios,
  ) async {
    ejerciciosGuardados[rutinaId] = ejercicios;
    return rutinasGuardadas
        .firstWhere((r) => r.id == rutinaId)
        .copyWith(ejercicios: ejercicios);
  }

  @override
  Future<List<Sesion>> sesiones(String usuarioId) async => sesionesGuardadas;

  @override
  Future<Sesion> crearSesion(String usuarioId, Sesion sesion) async {
    sesionesGuardadas = [...sesionesGuardadas, sesion];
    return sesion;
  }

  @override
  Future<Sesion> actualizarSesion(String usuarioId, Sesion sesion) async {
    sesionesGuardadas = [
      for (final s in sesionesGuardadas) s.id == sesion.id ? sesion : s,
    ];
    return sesion;
  }

  @override
  Future<void> borrarSesion(String usuarioId, int sesionId) async {
    sesionesGuardadas = [
      for (final s in sesionesGuardadas)
        if (s.id != sesionId) s,
    ];
  }

  /// Registros de calorías por día (a medianoche).
  final registrosCalorias = <DateTime, RegistroCalorias>{};

  @override
  Future<RegistroCalorias?> registroCalorias(
    String usuarioId,
    DateTime fecha,
  ) async => registrosCalorias[fecha];

  @override
  Future<RegistroCalorias> guardarRegistroCalorias(
    String usuarioId,
    RegistroCalorias registro,
  ) async => registrosCalorias[registro.fecha] = registro;

  @override
  Future<List<EjercicioCatalogo>> catalogoEjercicios() async =>
      catalogoGuardado;
}

EjercicioCatalogo ejercicioCatalogo(String id, String nombre, String grupo) =>
    EjercicioCatalogo(
      id: id,
      nombre: nombre,
      grupo: grupo,
      met: 6,
      categoria: 'Fuerza',
      equipo: 'Barra',
      musculos: const [],
      nivel: 'Principiante',
      descripcion: '',
      musculosSecundarios: const [],
      instrucciones: const [],
      consejos: const [],
    );

Ejercicio ejercicio(int id, String grupo) => Ejercicio(
  id: id,
  nombre: 'Ejercicio $id',
  grupo: grupo,
  series: 3,
  repeticiones: 10,
  carga: '20 kg',
  descansoSeg: 60,
);

EjercicioSesion ejercicioSesion(
  String grupo,
  List<Serie> series, {
  double? met,
}) => EjercicioSesion(
  id: series.length,
  catalogoId: '',
  nombre: grupo,
  grupo: grupo,
  met: met,
  series: series,
);

Sesion sesion(
  String nombre,
  DateTime inicio,
  int minutos, {
  int? rutinaId,
  List<EjercicioSesion> ejercicios = const [],
}) => Sesion(
  id: inicio.millisecondsSinceEpoch,
  nombre: nombre,
  rutinaId: rutinaId,
  inicio: inicio,
  fin: inicio.add(Duration(minutes: minutos)),
  ejercicios: ejercicios,
);
