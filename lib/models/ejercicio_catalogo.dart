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
    // required this.nivel // Si quisieramos agregar el nivel de dificultad
    this.imagen,
  });

  final String id;
  final String nombre;
  final String grupo;
  final double met;
  final String categoria;
  final String equipo;
  final List<String> musculos;

  final String? imagen;

  factory EjercicioCatalogo.fromFila(Map<String, dynamic> fila) =>
      EjercicioCatalogo(
        id: fila['id'] as String,
        nombre: fila['nombre'] as String,
        grupo: fila['grupo'] as String,
        met: (fila['met'] as num).toDouble(),
        categoria: fila['categoria'] as String,
        equipo: fila['equipo'] as String,
        musculos: (fila['musculos'] as List<dynamic>).cast<String>(),
        imagen: fila['imagen'] as String?,
      );
}
