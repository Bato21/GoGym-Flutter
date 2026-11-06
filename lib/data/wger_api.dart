import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ejercicio_wger.dart';

/// Cliente de la API REST de wger. Sus endpoints públicos no piden API key.
/// Recibe el [http.Client] por constructor para que las pruebas usen uno
/// falso (MockClient) y no dependan de internet.
class WgerApi {
  WgerApi({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  static const _base = 'https://wger.de/api/v2';

  /// Cada ejercicio trae todas sus traducciones, así que la respuesta pesa
  /// (~12 KB por ejercicio): se pide una sola página.
  static const limite = 60;

  /// GET /exerciseinfo/. Los ejercicios con imagen van primero; se descartan
  /// los que no tienen nombre en español ni en inglés.
  Future<List<EjercicioWger>> ejercicios() async {
    final url = Uri.parse('$_base/exerciseinfo/?limit=$limite&offset=0');
    final respuesta = await _cliente
        .get(url, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (respuesta.statusCode != 200) {
      throw WgerException('wger respondió ${respuesta.statusCode}');
    }
    // utf8.decode: sin esto las tildes llegan rotas.
    final cuerpo =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final ejercicios = [
      for (final e in cuerpo['results'] as List? ?? const [])
        ?EjercicioWger.fromJson(e as Map<String, dynamic>),
    ];
    // sort de Dart no es estable: se separa en dos listas para no
    // desordenar el resto.
    return [
      ...ejercicios.where((e) => e.imagen != null),
      ...ejercicios.where((e) => e.imagen == null),
    ];
  }
}

class WgerException implements Exception {
  const WgerException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
