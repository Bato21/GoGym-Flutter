/// Un ejercicio del catálogo es una fila de la tabla `ejercicios'
class EjercicioCatalogo {
  const EjercicioCatalogo({
    required this.id,
    required this.nombre,
    required this.grupo,
    required this.met,
    required this.categoria,
    required this.equipo,
    required this.musculos,
    required this.nivel,
    required this.descripcion,
    required this.musculosSecundarios,
    required this.instrucciones,
    required this.consejos,
    this.imagen,
  });

  final String id;
  final String nombre;
  final String grupo;
  final double met;
  final String categoria;
  final String equipo;
  final List<String> musculos;
  final String nivel;
  final String descripcion;
  final List<String> musculosSecundarios;
  final List<String> instrucciones;
  final List<String> consejos;
  final String? imagen;

  /// Imagenes de RepDB por jsDelivr, fijadas a un commit para que no cambien
  static const _baseImage =
      'https://cdn.jsdelivr.net/gh/RepDB/exercise-dataset@6d88fc6f3a398845f7f2c17f3a5f45cfc4effa2f/images/flat/';

  /// URL completa de un nombre de archivo de RepDB.
  static String urlDe(String imagen) => '$_baseImage$imagen';

  /// URL completa de la imagen, o null si el ejercicio no tiene
  String? get urlImagen => imagen == null ? null : urlDe(imagen!);

  factory EjercicioCatalogo.fromFila(Map<String, dynamic> fila) =>
      EjercicioCatalogo(
        id: fila['id'] as String,
        nombre: fila['nombre'] as String,
        grupo: fila['grupo'] as String,
        met: (fila['met'] as num).toDouble(),
        categoria: fila['categoria'] as String,
        equipo: fila['equipo'] as String,
        musculos: (fila['musculos'] as List<dynamic>).cast<String>(),
        nivel: fila['nivel'] as String,
        descripcion: fila['descripcion'] as String,
        musculosSecundarios: (fila['musculos_secundarios'] as List<dynamic>)
            .cast<String>(),
        instrucciones: (fila['instrucciones'] as List<dynamic>).cast<String>(),
        consejos: (fila['consejos'] as List<dynamic>).cast<String>(),
        imagen: fila['imagen'] as String?,
      );
}

/// Orden en que se muestran los filtros. Coincide con el check de la tabla.
const gruposMusculares = [
  'Pecho',
  'Espalda',
  'Hombro',
  'Bíceps',
  'Tríceps',
  'Pierna',
  'Core',
  'Antebrazo',
  'Cuerpo completo',
];
