import 'package:flutter/material.dart';

import '../models/ejercicio_wger.dart';
import '../widgets/ejercicio_wger_card.dart';

/// Detalle de un ejercicio de wger: imagen (Hero desde la lista), músculos,
/// equipamiento e instrucciones. Recibe el objeto por constructor.
class WgerDetallePage extends StatelessWidget {
  const WgerDetallePage({super.key, required this.ejercicio});

  final EjercicioWger ejercicio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final texto = tema.textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'wger-${ejercicio.id}',
                child: ImagenWger(url: ejercicio.imagen, tamanoIcono: 96),
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
                    Chip(label: Text(ejercicio.categoria)),
                    for (final equipo in ejercicio.equipamiento)
                      Chip(label: Text(equipo)),
                  ],
                ),
                if (!ejercicio.enEspanol) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Este ejercicio aún no tiene traducción al español en wger; '
                    'se muestra en inglés.',
                    style: texto.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (ejercicio.musculos.isNotEmpty ||
                    ejercicio.musculosSecundarios.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Músculos', style: texto.titleMedium),
                  const SizedBox(height: 8),
                  if (ejercicio.musculos.isNotEmpty)
                    Text('Principales: ${ejercicio.musculos.join(', ')}'),
                  if (ejercicio.musculosSecundarios.isNotEmpty)
                    Text(
                      'Secundarios: ${ejercicio.musculosSecundarios.join(', ')}',
                    ),
                ],
                const SizedBox(height: 24),
                Text('Cómo se hace', style: texto.titleMedium),
                const SizedBox(height: 8),
                Text(
                  ejercicio.descripcion.isEmpty
                      ? 'wger no tiene instrucciones para este ejercicio.'
                      : ejercicio.descripcion,
                  style: texto.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Fuente: wger.de (CC-BY-SA 4.0)',
                  style: texto.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
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
