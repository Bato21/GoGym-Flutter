/// Un ejercicio de la API pública de wger (https://wger.de/api/v2/exerciseinfo/).
/// wger trae el texto en varios idiomas: se usa el español y, si falta, el
/// inglés. Categorías, músculos y equipamiento vienen en inglés y se traducen
/// con las tablas de abajo.
class EjercicioWger {
  const EjercicioWger({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.musculos,
    required this.musculosSecundarios,
    required this.equipamiento,
    required this.enEspanol,
    this.imagen,
  });

  final int id;
  final String nombre;

  /// Instrucciones en texto plano (wger las manda en HTML).
  final String descripcion;
  final String categoria;
  final List<String> musculos;
  final List<String> musculosSecundarios;
  final List<String> equipamiento;

  /// false si no había traducción al español y se muestra el texto en inglés.
  final bool enEspanol;

  /// URL de la imagen principal; null si el ejercicio no tiene.
  final String? imagen;

  static const idiomaEspanol = 4;
  static const idiomaIngles = 2;

  /// null si el ejercicio no tiene traducción en español ni en inglés.
  static EjercicioWger? fromJson(Map<String, dynamic> json) {
    final traducciones = [
      for (final t in json['translations'] as List? ?? const [])
        t as Map<String, dynamic>,
    ];
    Map<String, dynamic>? enIdioma(int idioma) =>
        traducciones.where((t) => t['language'] == idioma).firstOrNull;
    final espanol = enIdioma(idiomaEspanol);
    final traduccion = espanol ?? enIdioma(idiomaIngles);
    final nombre = (traduccion?['name'] as String? ?? '').trim();
    if (traduccion == null || nombre.isEmpty) return null;

    final imagenes = [
      for (final i in json['images'] as List? ?? const [])
        i as Map<String, dynamic>,
    ];
    final principal =
        imagenes.where((i) => i['is_main'] == true).firstOrNull ??
        imagenes.firstOrNull;

    List<String> musculosDe(String clave) => [
      for (final m in json[clave] as List? ?? const [])
        _traducir(
          _musculos,
          (m['name_en'] as String?)?.isNotEmpty == true
              ? m['name_en'] as String
              : m['name'] as String? ?? '',
        ),
    ];

    return EjercicioWger(
      id: (json['id'] as num).toInt(),
      nombre: nombre,
      descripcion: textoPlano(traduccion['description'] as String? ?? ''),
      categoria: _traducir(
        _categorias,
        (json['category'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      ),
      musculos: musculosDe('muscles'),
      musculosSecundarios: musculosDe('muscles_secondary'),
      equipamiento: [
        for (final e in json['equipment'] as List? ?? const [])
          _traducir(_equipos, e['name'] as String? ?? ''),
      ],
      enEspanol: espanol != null,
      imagen: principal?['image'] as String?,
    );
  }
}

/// Orden de los filtros de la vista wger. Son las categorías de la API.
const categoriasWger = [
  'Pecho',
  'Espalda',
  'Hombros',
  'Brazos',
  'Piernas',
  'Pantorrillas',
  'Abdominales',
  'Cardio',
];

const _categorias = {
  'Abs': 'Abdominales',
  'Arms': 'Brazos',
  'Back': 'Espalda',
  'Calves': 'Pantorrillas',
  'Cardio': 'Cardio',
  'Chest': 'Pecho',
  'Legs': 'Piernas',
  'Shoulders': 'Hombros',
};

const _musculos = {
  'Shoulders': 'Hombros',
  'Biceps': 'Bíceps',
  'Hamstrings': 'Isquiotibiales',
  'Brachialis': 'Braquial',
  'Calves': 'Pantorrillas',
  'Glutes': 'Glúteos',
  'Lats': 'Dorsales',
  'Obliquus externus abdominis': 'Oblicuos',
  'Chest': 'Pecho',
  'Quads': 'Cuádriceps',
  'Abs': 'Abdominales',
  'Serratus anterior': 'Serrato anterior',
  'Soleus': 'Sóleo',
  'Trapezius': 'Trapecio',
  'Triceps': 'Tríceps',
};

const _equipos = {
  'Barbell': 'Barra',
  'Bench': 'Banco',
  'Cable machine': 'Polea',
  'Dumbbell': 'Mancuernas',
  'Gym mat': 'Colchoneta',
  'Incline bench': 'Banco inclinado',
  'Kettlebell': 'Kettlebell',
  'Pull-up bar': 'Barra de dominadas',
  'Resistance band': 'Banda elástica',
  'SZ-Bar': 'Barra Z',
  'Swiss Ball': 'Pelota suiza',
  'none (bodyweight exercise)': 'Peso corporal',
};

/// Si wger agrega un nombre nuevo, se muestra tal cual en vez de fallar.
String _traducir(Map<String, String> tabla, String nombre) =>
    tabla[nombre] ?? nombre;

/// Convierte el HTML de wger en texto: cada párrafo o paso en su línea, los
/// pasos de una lista con viñeta, sin etiquetas ni entidades.
String textoPlano(String html) {
  var texto = html
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|ol|ul|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entidades = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
  };
  entidades.forEach(
    (entidad, valor) => texto = texto.replaceAll(entidad, valor),
  );
  return texto
      .split('\n')
      .map((linea) => linea.trim())
      .where((linea) => linea.isNotEmpty)
      .join('\n');
}
