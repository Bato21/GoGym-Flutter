import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_repositorio.dart';
import '../models/ejercicio_catalogo.dart';
import 'ejercicio_detalle_page.dart';

/// Catálogo de ejercicios traído desde Supabase.
class BibliotecaPage extends StatefulWidget {
  const BibliotecaPage({super.key});

  @override
  State<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends State<BibliotecaPage> {
  late final Future<List<EjercicioCatalogo>> _catalogo;
  String _grupo = 'Todos';

  @override
  void initState() {
    super.initState();
    _catalogo = context.read<DatosRepositorio>().catalogoEjercicios();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              final ejercicios = snapshot.requireData
                  .where((e) => _grupo == 'Todos' || e.grupo == _grupo)
                  .toList();
              return ListView.builder(
                itemCount: ejercicios.length,
                itemBuilder: (context, index) {
                  final ejercicio = ejercicios[index];

                  // Imagen de RepDB si existe; si no hay o no carga, un ícono.
                  // Tamaño fijo para que la fila no salte al cargar la imagen.
                  return ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EjercicioDetallePage(ejercicio: ejercicio),
                      ),
                    ),
                    leading: Hero(
                      tag: 'imagen-${ejercicio.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ejercicio.urlImagen == null
                              ? const Icon(Icons.fitness_center)
                              : Image.network(
                                  ejercicio.urlImagen!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(Icons.fitness_center),
                                ),
                        ),
                      ),
                    ),
                    title: Text(ejercicio.nombre),
                    subtitle: Text(
                      '${ejercicio.equipo} · ${ejercicio.musculos.join(', ')}',
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
