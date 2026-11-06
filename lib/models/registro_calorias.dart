import '../utils/fechas.dart';

/// Tipos de comida que se ofrecen al registrar, como en Ionic.
const tiposComida = ['Desayuno', 'Almuerzo', 'Once', 'Cena', 'Snack'];

/// Una comida del día: calorías y macronutrientes en gramos.
class Comida {
  const Comida({
    required this.id,
    required this.nombre,
    required this.kcal,
    this.proteina = 0,
    this.carbohidratos = 0,
    this.grasas = 0,
  });

  final int id;
  final String nombre;
  final int kcal;
  final double proteina;
  final double carbohidratos;
  final double grasas;

  factory Comida.fromJson(Map<String, dynamic> json) => Comida(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'] as String? ?? '',
    kcal: (json['kcal'] as num?)?.round() ?? 0,
    proteina: (json['proteina'] as num?)?.toDouble() ?? 0,
    carbohidratos: (json['carbohidratos'] as num?)?.toDouble() ?? 0,
    grasas: (json['grasas'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'kcal': kcal,
    'proteina': proteina,
    'carbohidratos': carbohidratos,
    'grasas': grasas,
  };
}

/// Ejercicio anotado a mano en Calorías (p. ej. 30 min de trote). Las kcal no
/// se guardan: se calculan con el MET y el peso del perfil.
class Actividad {
  const Actividad({
    required this.id,
    required this.nombre,
    required this.met,
    required this.minutos,
  });

  final int id;
  final String nombre;
  final double met;
  final int minutos;

  factory Actividad.fromJson(Map<String, dynamic> json) => Actividad(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'] as String? ?? '',
    met: (json['met'] as num?)?.toDouble() ?? 0,
    minutos: (json['minutos'] as num?)?.round() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'met': met,
    'minutos': minutos,
  };

  /// Estimación: MET × peso (kg) × horas. Aproximada, no exacta.
  double kcal(double pesoKg) => met * pesoKg * minutos / 60;
}

/// Comidas y actividades de un día. Es una fila de `registros_calorias`
/// (clave: user_id + fecha), compartida con la app de Ionic.
class RegistroCalorias {
  const RegistroCalorias({
    required this.fecha,
    this.comidas = const [],
    this.actividades = const [],
  });

  /// A medianoche, hora local.
  final DateTime fecha;
  final List<Comida> comidas;
  final List<Actividad> actividades;

  factory RegistroCalorias.fromFila(Map<String, dynamic> fila) =>
      RegistroCalorias(
        fecha: soloDia(DateTime.parse(fila['fecha'] as String)),
        comidas: [
          for (final c in fila['comidas'] as List? ?? const [])
            Comida.fromJson(c as Map<String, dynamic>),
        ],
        actividades: [
          for (final a in fila['actividades'] as List? ?? const [])
            Actividad.fromJson(a as Map<String, dynamic>),
        ],
      );

  /// Columnas de la fila, sin `user_id`: lo agrega el repositorio.
  Map<String, dynamic> toFila() => {
    'fecha': claveFecha(fecha),
    'comidas': [for (final c in comidas) c.toJson()],
    'actividades': [for (final a in actividades) a.toJson()],
  };

  RegistroCalorias copyWith({
    List<Comida>? comidas,
    List<Actividad>? actividades,
  }) => RegistroCalorias(
    fecha: fecha,
    comidas: comidas ?? this.comidas,
    actividades: actividades ?? this.actividades,
  );

  int get ingesta => comidas.fold(0, (suma, c) => suma + c.kcal);

  double get proteina => comidas.fold(0.0, (suma, c) => suma + c.proteina);
  double get carbohidratos =>
      comidas.fold(0.0, (suma, c) => suma + c.carbohidratos);
  double get grasas => comidas.fold(0.0, (suma, c) => suma + c.grasas);
}
