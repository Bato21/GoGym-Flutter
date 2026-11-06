import 'dart:convert';

import 'package:go_gym/data/wger_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Respuesta de GET /exerciseinfo/ recortada a lo que usa la app.
/// - 31: solo en inglés y sin imagen.
/// - 42: en español, con imagen (debe quedar primero).
/// - 53: sin español ni inglés (se descarta).
final respuestaWger = {
  'count': 3,
  'next': null,
  'results': [
    {
      'id': 31,
      'category': {'id': 15, 'name': 'Cardio'},
      'muscles': [],
      'muscles_secondary': [],
      'equipment': [
        {'id': 7, 'name': 'none (bodyweight exercise)'},
      ],
      'images': [],
      'translations': [
        {'language': 2, 'name': 'Jumping Jacks', 'description': '<p>Jump.</p>'},
      ],
    },
    {
      'id': 42,
      'category': {'id': 9, 'name': 'Legs'},
      'muscles': [
        {'id': 10, 'name': 'Quadriceps femoris', 'name_en': 'Quads'},
      ],
      'muscles_secondary': [
        {'id': 8, 'name': 'Gluteus maximus', 'name_en': 'Glutes'},
      ],
      'equipment': [
        {'id': 1, 'name': 'Barbell'},
      ],
      'images': [
        {'image': 'https://wger.de/media/sentadilla.png', 'is_main': true},
      ],
      'translations': [
        {'language': 2, 'name': 'Squat', 'description': '<p>Squat.</p>'},
        {
          'language': 4,
          'name': 'Sentadilla',
          'description':
              '<p>Con la barra en la espalda:</p><ol><li>Baja.</li>'
              '<li>Sube &amp; respira.</li></ol>',
        },
      ],
    },
    {
      'id': 53,
      'category': {'id': 10, 'name': 'Abs'},
      'muscles': [],
      'muscles_secondary': [],
      'equipment': [],
      'images': [],
      'translations': [
        {'language': 1, 'name': 'Crunch', 'description': ''},
      ],
    },
  ],
};

/// WgerApi con un cliente falso. [fallos] = cuántas llamadas responden 500
/// antes de responder bien. [pedidas] guarda las URLs pedidas.
WgerApi wgerFalso({int fallos = 0, List<Uri>? pedidas}) {
  var llamadas = 0;
  return WgerApi(
    cliente: MockClient((pedido) async {
      pedidas?.add(pedido.url);
      llamadas++;
      if (llamadas <= fallos) return http.Response('error', 500);
      return http.Response.bytes(
        utf8.encode(jsonEncode(respuestaWger)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}
