import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_repositorio.dart';
import '../models/ejercicio_catalogo.dart';
import 'ejercicio_detalle_page.dart';
import '../widgets/ejercicio_card.dart';

/// Catálogo de ejercicios traído desde Supabase.
class BibliotecaPage extends StatefulWidget {
  const BibliotecaPage({super.key});

  @override
  State<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends State<BibliotecaPage> {
  late final Future<List<EjercicioCatalogo>> _catalogo;
  String _grupo = 'Todos';

  /// Lo escrito en el buscador, ya normalizado (sin tildes, en minúsculas).
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _catalogo = context.read<DatosRepositorio>().catalogoEjercicios();
  }

  /// true si el nombre o el equipo contienen lo buscado.
  /// Con el buscador vacío, todo coincide.
  bool _coincideConBusqueda(EjercicioCatalogo ejercicio) {
    if (_busqueda.isEmpty) return true;
    return _normalizar(ejercicio.nombre).contains(_busqueda) ||
        _normalizar(ejercicio.equipo).contains(_busqueda);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Buscador. Cada letra llama a setState: build se vuelve a ejecutar y
        // la lista se filtra de nuevo, sin volver a consultar Supabase.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar ejercicio o equipo',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (texto) =>
                setState(() => _busqueda = _normalizar(texto)),
          ),
        ),
        // Fila de chips con scroll horizontal.
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: gruposMusculares.length + 1,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final grupo = i == 0 ? 'Todos' : gruposMusculares[i - 1];
              return _ChipGrupo(
                texto: grupo,
                seleccionado: grupo == _grupo,
                onTap: () => setState(() => _grupo = grupo),
              );
            },
          ),
        ),
        // La lista ocupa el resto del alto.
        Expanded(
          child: FutureBuilder<List<EjercicioCatalogo>>(
            future: _catalogo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              // Un ejercicio se muestra si cumple los dos filtros a la vez.
              final ejercicios = snapshot.requireData
                  .where((e) => _grupo == 'Todos' || e.grupo == _grupo)
                  .where(_coincideConBusqueda)
                  .toList();
              if (ejercicios.isEmpty) {
                return const Center(child: Text('Sin resultados.'));
              }
              return ListView.builder(
                itemCount: ejercicios.length,
                itemBuilder: (context, index) {
                  final ejercicio = ejercicios[index];
                  return EjercicioCard(
                    ejercicio: ejercicio,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EjercicioDetallePage(ejercicio: ejercicio),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pasa a minúsculas y quita las tildes, para que "biceps" encuentre
/// "Curl de Bíceps". Dart no trae una función para quitar tildes, así que
/// se reemplazan una por una.
String _normalizar(String texto) {
  const conTilde = 'áéíóúüñ';
  const sinTilde = 'aeiouun';
  var resultado = texto.trim().toLowerCase();
  for (var i = 0; i < conTilde.length; i++) {
    resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
  }
  return resultado;
}

/// Chip de filtro que anima color y borde al seleccionarse.
class _ChipGrupo extends StatelessWidget {
  const _ChipGrupo({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: seleccionado ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: seleccionado ? colores.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colores.primary),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? colores.onPrimary : colores.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
