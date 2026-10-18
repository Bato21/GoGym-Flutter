import 'package:flutter/material.dart';

import '../models/ejercicio_catalogo.dart';

/// Detalle de un ejercicio del catálogo. Lo recibe por constructor.
class EjercicioDetallePage extends StatelessWidget {
  const EjercicioDetallePage({super.key, required this.ejercicio});

  final EjercicioCatalogo ejercicio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cabecera con la imagen: se encoge al hacer scroll.
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'imagen-${ejercicio.id}',
                child: ejercicio.urlImagen == null
                    ? const Icon(Icons.fitness_center, size: 96)
                    : Image.network(
                        ejercicio.urlImagen!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.fitness_center, size: 96),
                      ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text(ejercicio.nombre, style: texto.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final etiqueta in [
                      ejercicio.grupo,
                      ejercicio.nivel,
                      ejercicio.equipo,
                      ejercicio.categoria,
                    ])
                      Chip(label: Text(etiqueta)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(ejercicio.descripcion, style: texto.bodyLarge),
                _Seccion(
                  titulo: 'Músculos',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Principales: ${ejercicio.musculos.join(', ')}'),
                      if (ejercicio.musculosSecundarios.isNotEmpty)
                        Text(
                          'Secundarios: '
                          '${ejercicio.musculosSecundarios.join(', ')}',
                        ),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Cómo se hace',
                  child: Column(
                    children: [
                      for (final (i, paso) in ejercicio.instrucciones.indexed)
                        _Fila(
                          icono: CircleAvatar(
                            radius: 12,
                            child: Text('${i + 1}', style: texto.labelSmall),
                          ),
                          texto: paso,
                        ),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Consejos',
                  child: Column(
                    children: [
                      for (final consejo in ejercicio.consejos)
                        _Fila(
                          icono: const Icon(Icons.lightbulb_outline, size: 22),
                          texto: consejo,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección con su contenido debajo.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Un ícono a la izquierda y un texto que puede ocupar varias líneas.
class _Fila extends StatelessWidget {
  const _Fila({required this.icono, required this.texto});

  final Widget icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icono,
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
