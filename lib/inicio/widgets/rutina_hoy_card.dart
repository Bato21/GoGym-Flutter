import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/pressable_scale.dart';
import '../../widgets/tarjeta.dart';
import 'animaciones.dart';

/// Tarjeta destacada con la rutina que toca y un botón para empezarla.
/// Se hunde al presionarla, la cruza un destello al aparecer y el ícono del
/// botón invita a tocarlo.
class RutinaHoyCard extends StatelessWidget {
  const RutinaHoyCard({
    super.key,
    required this.etiqueta,
    required this.titulo,
    required this.detalle,
    required this.textoBoton,
    required this.onPressed,
  });

  /// "Toca hoy", "Próximo entreno · Miércoles"…
  final String etiqueta;
  final String titulo;
  final String detalle;
  final String textoBoton;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return PressableScale(
      child: Destello(
        radio: Tarjeta.radio,
        child: Tarjeta(
          destacada: true,
          onTap: onPressed,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etiqueta.toUpperCase(),
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: colores.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titulo,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const _IconoEmpezar(),
                label: Text(textoBoton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colores.primary,
                  side: BorderSide(color: colores.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flecha que entra deslizándose y da un pequeño empujón hacia adelante.
class _IconoEmpezar extends StatelessWidget {
  const _IconoEmpezar();

  @override
  Widget build(BuildContext context) {
    return Progreso(
      retraso: const Duration(milliseconds: 900),
      duracion: const Duration(milliseconds: 900),
      curva: Curves.linear,
      builder: (context, t) {
        // Entra desde la izquierda y luego dos empujones que se apagan.
        final entrada = Curves.easeOutCubic.transform((t * 2.5).clamp(0, 1));
        final empujon = t < 0.4
            ? 0.0
            : math.sin((t - 0.4) / 0.6 * math.pi * 2).abs() * 3 * (1 - t);
        return Opacity(
          opacity: entrada,
          child: Transform.translate(
            offset: Offset(-8 * (1 - entrada) + empujon, 0),
            child: const Icon(Icons.play_arrow_rounded, size: 18),
          ),
        );
      },
    );
  }
}
