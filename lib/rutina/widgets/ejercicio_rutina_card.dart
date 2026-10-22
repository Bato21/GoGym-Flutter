import 'package:flutter/material.dart';

import '../../models/rutina.dart';
import '../../widgets/aparecer.dart';
import '../../widgets/tarjeta.dart';

/// Un ejercicio dentro del detalle de la rutina. Al tocarlo se despliega con
/// sus series y el descanso; el asa de la derecha permite arrastrarlo.
/// [atenuado] lo deja en segundo plano cuando se filtra por otro grupo.
class EjercicioRutinaCard extends StatelessWidget {
  const EjercicioRutinaCard({
    super.key,
    required this.ejercicio,
    required this.indice,
    required this.expandido,
    required this.onTap,
    this.atenuado = false,
  });

  final Ejercicio ejercicio;

  /// Posición en la lista; la usa el asa para arrastrar.
  final int indice;
  final bool expandido;
  final bool atenuado;
  final VoidCallback onTap;

  static const _duracion = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return AnimatedOpacity(
      opacity: atenuado ? 0.35 : 1,
      duration: _duracion,
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: atenuado ? 0.97 : 1,
        duration: _duracion,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: _duracion,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: expandido
                ? colores.primary.withValues(alpha: 0.08)
                : colores.surfaceContainer,
            borderRadius: Tarjeta.radio,
            border: Border.all(
              color: expandido ? colores.primary : colores.outlineVariant,
              width: expandido ? 1.5 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: Tarjeta.radio,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _Miniatura(url: ejercicio.urlImagen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ejercicio.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ejercicio.resumen,
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: colores.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: expandido ? 0.5 : 0,
                          duration: _duracion,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more,
                            size: 20,
                            color: expandido
                                ? colores.primary
                                : colores.onSurfaceVariant,
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: indice,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Icon(
                              Icons.drag_indicator,
                              semanticLabel: 'Arrastrar para reordenar',
                              color: colores.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: _duracion,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: expandido
                          ? _Detalle(ejercicio: ejercicio)
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Imagen del catálogo, con un fundido al terminar de cargar.
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final respaldo = ColoredBox(
      color: colores.primary.withValues(alpha: 0.1),
      child: Icon(Icons.fitness_center, size: 18, color: colores.primary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 44,
        height: 44,
        child: url == null
            ? respaldo
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => respaldo,
                frameBuilder: (context, child, frame, sincrono) => sincrono
                    ? child
                    : AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: child,
                      ),
              ),
      ),
    );
  }
}

/// Series planificadas y descanso, en cascada al desplegarse.
class _Detalle extends StatelessWidget {
  const _Detalle({required this.ejercicio});

  final Ejercicio ejercicio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final repeticiones = ejercicio.repeticiones > 0
        ? '${ejercicio.repeticiones}'
        : '–';
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 8, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < ejercicio.series; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Aparecer(
                    indice: i,
                    desde: const Offset(0, 10),
                    paso: const Duration(milliseconds: 45),
                    child: _Serie(numero: i + 1, repeticiones: repeticiones),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (ejercicio.carga.isNotEmpty)
                _Dato(
                  icono: Icons.monitor_weight_outlined,
                  texto: ejercicio.carga,
                ),
              if (ejercicio.descansoSeg > 0)
                _Dato(
                  icono: Icons.hourglass_bottom,
                  texto: 'Descanso ${formatearDescanso(ejercicio.descansoSeg)}',
                ),
              if (ejercicio.grupo.isNotEmpty)
                _Dato(icono: Icons.accessibility_new, texto: ejercicio.grupo),
            ],
          ),
          if (ejercicio.series == 0)
            Text(
              'Sin series planificadas.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 90 → "1:30", 45 → "45 s".
String formatearDescanso(int segundos) {
  if (segundos < 60) return '$segundos s';
  final resto = segundos % 60;
  return '${segundos ~/ 60}:${resto.toString().padLeft(2, '0')}';
}

class _Serie extends StatelessWidget {
  const _Serie({required this.numero, required this.repeticiones});

  final int numero;
  final String repeticiones;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colores.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            repeticiones,
            style: tema.textTheme.titleSmall?.copyWith(
              color: colores.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'S$numero',
            style: tema.textTheme.labelSmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = tema.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 4),
        Text(texto, style: tema.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
