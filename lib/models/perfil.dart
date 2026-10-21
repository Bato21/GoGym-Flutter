import '../utils/fechas.dart';

/// Datos del usuario. Es una fila de la tabla `perfiles`.
class Perfil {
  const Perfil({
    required this.nombre,
    required this.apellido,
    required this.objetivo,
    required this.pesoKg,
    required this.diasEntrenamiento,
    required this.horaEntrenamiento,
    required this.metaCalorias,
    this.rutinaFavoritaId,
  });

  final String nombre;
  final String apellido;
  final String objetivo;
  final int? rutinaFavoritaId;

  /// Se usa para estimar calorías quemadas (MET × peso × horas).
  final double pesoKg;

  /// Días en que entrena, 0 = lunes … 6 = domingo.
  final List<int> diasEntrenamiento;

  /// Hora habitual, "HH:mm".
  final String horaEntrenamiento;
  final int metaCalorias;

  Perfil copyWith({
    String? nombre,
    String? apellido,
    String? objetivo,
    int? rutinaFavoritaId,
    bool quitarRutinaFavorita = false,
    double? pesoKg,
    List<int>? diasEntrenamiento,
    String? horaEntrenamiento,
    int? metaCalorias,
  }) =>
      Perfil(
        nombre: nombre ?? this.nombre,
        apellido: apellido ?? this.apellido,
        objetivo: objetivo ?? this.objetivo,
        rutinaFavoritaId: quitarRutinaFavorita
            ? null
            : rutinaFavoritaId ?? this.rutinaFavoritaId,
        pesoKg: pesoKg ?? this.pesoKg,
        diasEntrenamiento: diasEntrenamiento ?? this.diasEntrenamiento,
        horaEntrenamiento: horaEntrenamiento ?? this.horaEntrenamiento,
        metaCalorias: metaCalorias ?? this.metaCalorias,
      );

  /// Columnas editables de la fila `perfiles`.
  Map<String, dynamic> toUpdate() => {
        'nombre': nombre,
        'apellido': apellido,
        'objetivo': objetivo,
        'rutina_favorita_id': rutinaFavoritaId,
        'peso_kg': pesoKg,
        'dias_entrenamiento': diasEntrenamiento,
        'hora_entrenamiento': horaEntrenamiento,
        'meta_calorias': metaCalorias,
      };

  factory Perfil.fromFila(Map<String, dynamic> fila) => Perfil(
        nombre: fila['nombre'] as String? ?? '',
        apellido: fila['apellido'] as String? ?? '',
        objetivo: fila['objetivo'] as String? ?? '',
        rutinaFavoritaId: (fila['rutina_favorita_id'] as num?)?.toInt(),
        pesoKg: (fila['peso_kg'] as num).toDouble(),
        diasEntrenamiento: [
          for (final d in fila['dias_entrenamiento'] as List? ?? const [])
            (d as num).toInt(),
        ],
        // La columna es time: llega como "18:00:00".
        horaEntrenamiento:
            (fila['hora_entrenamiento'] as String? ?? '').split(':').take(2).join(':'),
        metaCalorias: (fila['meta_calorias'] as num).toInt(),
      );

  /// "VR" para el avatar; vacío si todavía no hay nombre.
  String get iniciales {
    String primera(String texto) =>
        texto.trim().isEmpty ? '' : texto.trim()[0];
    return (primera(nombre) + primera(apellido)).toUpperCase();
  }

  bool esDiaEntrenamiento(DateTime fecha) =>
      diasEntrenamiento.contains(indiceDia(fecha));

  /// El siguiente día de entrenamiento después de [fecha] (sin incluirla).
  DateTime? proximoDiaEntrenamiento(DateTime fecha) {
    for (var i = 1; i <= 7; i++) {
      final dia = sumarDias(fecha, i);
      if (esDiaEntrenamiento(dia)) return dia;
    }
    return null;
  }
}
