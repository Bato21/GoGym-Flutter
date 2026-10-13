import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../utils/fechas.dart';
import '../../widgets/tarjeta.dart';

enum EstadoDia {
  /// Hubo al menos un entrenamiento.
  entrenado,

  /// Hoy, todavía sin entrenar.
  hoy,

  /// Ya pasó y no hubo entrenamiento.
  descanso,

  /// Aún no llega.
  futuro,
}

/// Racha actual, récord y los 7 días de la semana en curso.
class RachaCard extends StatelessWidget {
  const RachaCard({
    super.key,
    required this.actual,
    required this.record,
    required this.dias,
  }) : assert(dias.length == 7);

  final int actual;
  final int record;

  /// De lunes a domingo.
  final List<EstadoDia> dias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Tarjeta(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 20, color: colores.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$actual ${actual == 1 ? 'día seguido' : 'días seguidos'}',
                  style: tema.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Récord $record',
                style: tema.textTheme.labelSmall
                    ?.copyWith(color: colores.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Dia(inicial: inicialesSemana[i], estado: dias[i]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.inicial, required this.estado});

  final String inicial;
  final EstadoDia estado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    const radio = BorderRadius.all(Radius.circular(7));

    final Widget cuadro = switch (estado) {
      EstadoDia.entrenado => DecoratedBox(
          decoration:
              BoxDecoration(color: colores.primary, borderRadius: radio)),
      EstadoDia.descanso => DecoratedBox(
          decoration: BoxDecoration(
              color: colores.primary.withValues(alpha: 0.12),
              borderRadius: radio)),
      EstadoDia.futuro => DecoratedBox(
          decoration: BoxDecoration(
              border: Border.all(color: colores.outlineVariant),
              borderRadius: radio)),
      EstadoDia.hoy => CustomPaint(
          painter: _BordePunteado(color: colores.onSurfaceVariant)),
    };

    return Semantics(
      label: '$inicial: ${estado.name}',
      child: Column(
        children: [
          AspectRatio(aspectRatio: 1.15, child: cuadro),
          const SizedBox(height: 4),
          Text(
            inicial,
            style: tema.textTheme.labelSmall?.copyWith(
              color: estado == EstadoDia.entrenado
                  ? colores.onSurface
                  : colores.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Borde punteado redondeado para el día de hoy (como en el mockup).
class _BordePunteado extends CustomPainter {
  _BordePunteado({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final borde = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.6),
        const Radius.circular(7),
      ));
    const trazo = 4.0;
    const hueco = 3.0;
    for (final PathMetric tramo in borde.computeMetrics()) {
      for (var d = 0.0; d < tramo.length; d += trazo + hueco) {
        canvas.drawPath(tramo.extractPath(d, d + trazo), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado anterior) => anterior.color != color;
}
