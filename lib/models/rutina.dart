import 'ejercicio_catalogo.dart';

/// MET para ejercicios sin dato del catálogo (fuerza moderada).
const double metPorDefecto = 5;

/// Un ejercicio planificado dentro de una rutina.
class Ejercicio {
  const Ejercicio({
    required this.id,
    required this.nombre,
    required this.grupo,
    required this.series,
    required this.repeticiones,
    required this.carga,
    required this.descansoSeg,
    this.catalogoId,
    this.imagen,
    this.met,
    this.json = const {},
  });

  final int id;
  final String nombre;
  final String grupo;
  final int series;
  final int repeticiones;

  /// '45 kg' | 'Peso corporal' | '60 s'
  final String carga;
  final int descansoSeg;
  final String? catalogoId;
  final String? imagen;
  final double? met;

  /// El objeto tal como vino de la tabla. [toJson] parte de él para no perder
  /// campos que guarda la app de Ionic y que aquí no se usan.
  final Map<String, dynamic> json;

  String? get urlImagen =>
      imagen == null ? null : EjercicioCatalogo.urlDe(imagen!);

  /// "4 × 8 · 45 kg", "3 × 10 · Peso corporal" o "3 series · 60 s".
  String get resumen {
    final volumen = repeticiones > 0
        ? '$series × $repeticiones'
        : '$series ${series == 1 ? 'serie' : 'series'}';
    return carga.isEmpty ? volumen : '$volumen · $carga';
  }

  Map<String, dynamic> toJson() => {
        ...json,
        'id': id,
        'nombre': nombre,
        'grupo': grupo,
        'series': series,
        'repeticiones': repeticiones,
        'carga': carga,
        'descansoSeg': descansoSeg,
        if (catalogoId != null) 'catalogoId': catalogoId,
        if (imagen != null) 'imagen': imagen,
        if (met != null) 'met': met,
      };

  factory Ejercicio.fromJson(Map<String, dynamic> json) => Ejercicio(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String? ?? '',
        grupo: json['grupo'] as String? ?? '',
        series: (json['series'] as num?)?.toInt() ?? 0,
        repeticiones: (json['repeticiones'] as num?)?.toInt() ?? 0,
        carga: json['carga'] as String? ?? '',
        descansoSeg: (json['descansoSeg'] as num?)?.toInt() ?? 0,
        catalogoId: json['catalogoId'] as String?,
        imagen: json['imagen'] as String?,
        met: (json['met'] as num?)?.toDouble(),
        json: json,
      );
}

/// Una rutina del usuario. Es una fila de la tabla `rutinas`.
class Rutina {
  const Rutina({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.nivel,
    required this.minutos,
    required this.ejercicios,
  });

  final int id;
  final String nombre;
  final String categoria;
  final String nivel;
  final int minutos;
  final List<Ejercicio> ejercicios;

  factory Rutina.fromFila(Map<String, dynamic> fila) => Rutina(
        id: (fila['id'] as num).toInt(),
        nombre: fila['nombre'] as String,
        categoria: fila['categoria'] as String? ?? '',
        nivel: fila['nivel'] as String? ?? '',
        minutos: (fila['minutos'] as num?)?.toInt() ?? 0,
        ejercicios: [
          for (final e in fila['ejercicios'] as List? ?? const [])
            Ejercicio.fromJson(e as Map<String, dynamic>),
        ],
      );

  Rutina copyWith({List<Ejercicio>? ejercicios}) => Rutina(
        id: id,
        nombre: nombre,
        categoria: categoria,
        nivel: nivel,
        minutos: minutos,
        ejercicios: ejercicios ?? this.ejercicios,
      );

  /// "6 ejercicios · 55 min · Intermedio", sin las partes que falten.
  String get resumen => [
        '${ejercicios.length} '
            '${ejercicios.length == 1 ? 'ejercicio' : 'ejercicios'}',
        if (minutos > 0) '$minutos min',
        if (nivel.isNotEmpty) nivel,
      ].join(' · ');

  int get totalSeries => ejercicios.fold(0, (suma, e) => suma + e.series);

  /// Grupos musculares sin repetir, en el orden de los ejercicios.
  List<String> get grupos => [
        ...{
          for (final e in ejercicios)
            if (e.grupo.isNotEmpty) e.grupo,
        },
      ];
}
