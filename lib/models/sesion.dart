import 'rutina.dart';

/// Una serie hecha. null = el usuario no la rellenó.
class Serie {
  const Serie({this.kg, this.reps, this.rpe});

  final double? kg;
  final int? reps;

  /// Esfuerzo percibido (RPE): 1 = muy fácil, 10 = al fallo.
  final int? rpe;

  factory Serie.fromJson(Map<String, dynamic> json) => Serie(
        kg: (json['kg'] as num?)?.toDouble(),
        reps: (json['reps'] as num?)?.toInt(),
        rpe: (json['rpe'] as num?)?.toInt(),
      );

  /// kg × reps; 0 si falta alguno de los dos.
  double get volumen => (kg ?? 0) * (reps ?? 0);
}

/// Un ejercicio del catálogo dentro de un entrenamiento, con sus series.
class EjercicioSesion {
  const EjercicioSesion({
    required this.id,
    required this.catalogoId,
    required this.nombre,
    required this.grupo,
    required this.series,
    this.imagen,
    this.met,
    this.repsObjetivo,
  });

  final int id;
  final String catalogoId;
  final String nombre;
  final String grupo;
  final String? imagen;

  /// MET del catálogo, para estimar la quema. Falta en sesiones antiguas.
  final double? met;

  /// Repeticiones que pedía la rutina. Solo si vino de una rutina.
  final int? repsObjetivo;
  final List<Serie> series;

  factory EjercicioSesion.fromJson(Map<String, dynamic> json) => EjercicioSesion(
        id: (json['id'] as num).toInt(),
        catalogoId: json['catalogoId'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        grupo: json['grupo'] as String? ?? '',
        imagen: json['imagen'] as String?,
        met: (json['met'] as num?)?.toDouble(),
        repsObjetivo: (json['repsObjetivo'] as num?)?.toInt(),
        series: [
          for (final s in json['series'] as List? ?? const [])
            Serie.fromJson(s as Map<String, dynamic>),
        ],
      );
}

/// Un entrenamiento terminado. Es una fila de la tabla `sesiones`.
class Sesion {
  const Sesion({
    required this.id,
    required this.nombre,
    required this.inicio,
    required this.ejercicios,
    this.rutinaId,
    this.fin,
  });

  final int id;
  final String nombre;

  /// Rutina de la que salió; null en entrenamientos libres.
  final int? rutinaId;

  /// En hora local del dispositivo.
  final DateTime inicio;
  final DateTime? fin;
  final List<EjercicioSesion> ejercicios;

  factory Sesion.fromFila(Map<String, dynamic> fila) => Sesion(
        id: (fila['id'] as num).toInt(),
        nombre: fila['nombre'] as String,
        rutinaId: (fila['rutina_id'] as num?)?.toInt(),
        inicio: DateTime.parse(fila['inicio'] as String).toLocal(),
        fin: fila['fin'] == null
            ? null
            : DateTime.parse(fila['fin'] as String).toLocal(),
        ejercicios: [
          for (final e in fila['ejercicios'] as List? ?? const [])
            EjercicioSesion.fromJson(e as Map<String, dynamic>),
        ],
      );

  /// Suma de kg × reps de todas las series.
  double get volumen => ejercicios
      .expand((e) => e.series)
      .fold(0.0, (suma, s) => suma + s.volumen);

  int get totalSeries =>
      ejercicios.fold(0, (suma, e) => suma + e.series.length);

  Duration get duracion {
    final diferencia = (fin ?? inicio).difference(inicio);
    return diferencia.isNegative ? Duration.zero : diferencia;
  }

  /// El grupo muscular con más series; null si no hay ejercicios con grupo.
  String? get grupoPrincipal {
    final seriesPorGrupo = <String, int>{};
    for (final e in ejercicios) {
      if (e.grupo.isEmpty) continue;
      seriesPorGrupo[e.grupo] = (seriesPorGrupo[e.grupo] ?? 0) + e.series.length;
    }
    if (seriesPorGrupo.isEmpty) return null;
    return seriesPorGrupo.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
  }

  /// MET medio de la sesión, ponderado por series (igual que en Calorías).
  double get met {
    final series = totalSeries;
    if (series == 0) return metPorDefecto;
    final total = ejercicios.fold(
        0.0, (suma, e) => suma + (e.met ?? metPorDefecto) * e.series.length);
    return total / series;
  }

  /// Estimación de la quema: MET × peso × horas. Es aproximada, no exacta.
  double kcalEstimadas(double pesoKg) =>
      met * pesoKg * duracion.inMinutes / 60;
}
