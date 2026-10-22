import 'package:flutter/material.dart';

import '../../models/rutina.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/tarjeta.dart';
import 'foto_rutina.dart';

/// Tag del Hero que lleva la portada de la lista al detalle.
String heroFotoRutina(int id) => 'foto-rutina-$id';

/// Una rutina en la lista: portada, nombre, resumen y grupos musculares.
/// [siguiente] la destaca como la que toca según la rotación.
class RutinaCard extends StatelessWidget {
  const RutinaCard({
    super.key,
    required this.rutina,
    required this.onTap,
    this.siguiente = false,
  });

  final Rutina rutina;
  final VoidCallback onTap;
  final bool siguiente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final etiqueta = [
      if (rutina.categoria.isNotEmpty) rutina.categoria,
      if (siguiente) 'Siguiente',
    ].join(' · ');
    return PressableScale(
      child: Tarjeta(
        destacada: siguiente,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Hero(
              tag: heroFotoRutina(rutina.id),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FotoRutina(
                  categoria: rutina.categoria,
                  radio: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (etiqueta.isNotEmpty)
                    Text(
                      etiqueta.toUpperCase(),
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: colores.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    rutina.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rutina.resumen,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: colores.onSurfaceVariant,
                    ),
                  ),
                  if (rutina.grupos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final grupo in rutina.grupos.take(3))
                          _Grupo(texto: grupo),
                        if (rutina.grupos.length > 3)
                          _Grupo(texto: '+${rutina.grupos.length - 3}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colores.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colores.outlineVariant),
      ),
      child: Text(
        texto,
        style: tema.textTheme.labelSmall?.copyWith(
          color: colores.onSurfaceVariant,
        ),
      ),
    );
  }
}
