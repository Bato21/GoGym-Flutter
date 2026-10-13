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

  /// Grupos musculares sin repetir, en el orden de los ejercicios.
  List<String> get grupos => [
        ...{
          for (final e in ejercicios)
            if (e.grupo.isNotEmpty) e.grupo,
        },
      ];
}
