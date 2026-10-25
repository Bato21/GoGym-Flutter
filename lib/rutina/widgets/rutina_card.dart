import 'package:flutter/material.dart';

import '../../models/rutina.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/tarjeta.dart';
import 'foto_rutina.dart';

/// Tag del Hero que lleva la portada de la lista al detalle.
String heroFotoRutina(int id) => 'foto-rutina-$id';

/// Una rutina en la lista: portada, nombre, resumen y grupos musculares.
/// [siguiente] la destaca como la que toca según la rotación y [orden] marca
/// su lugar en ella (null si no rota, p. ej. porque no tiene ejercicios).
class RutinaCard extends StatelessWidget {
  const RutinaCard({
    super.key,
    required this.rutina,
    required this.onTap,
    this.siguiente = false,
    this.orden,
  });

  final Rutina rutina;
  final VoidCallback onTap;
  final bool siguiente;
  final int? orden;

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
            Stack(
              clipBehavior: Clip.none,
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
                if (orden != null)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: _Orden(numero: orden!, destacado: siguiente),
                  ),
              ],
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

/// Círculo con el lugar de la rutina en la rotación.
class _Orden extends StatelessWidget {
  const _Orden({required this.numero, required this.destacado});

  final int numero;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Semantics(
      label: 'Número $numero en la rotación',
      excludeSemantics: true,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: destacado ? colores.primary : colores.surfaceContainer,
          border: Border.all(
            color: destacado ? colores.primary : colores.outlineVariant,
          ),
        ),
        child: Text(
          '$numero',
          style: tema.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: destacado ? colores.onPrimary : colores.onSurfaceVariant,
          ),
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
