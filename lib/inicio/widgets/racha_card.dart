import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../utils/fechas.dart';
import '../../widgets/tarjeta.dart';
import 'animaciones.dart';

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

/// Racha actual, récord y los 7 días de la semana en curso. Al aparecer, la
/// llama se enciende, el contador sube y los días se rellenan uno tras otro.
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
              _Llama(encendida: actual > 0),
              const SizedBox(width: 6),
              Expanded(
                child: NumeroAnimado(
                  valor: actual.toDouble(),
                  builder: (context, valor) {
                    final dias = valor.round();
                    return Text(
                      '$dias ${dias == 1 ? 'día seguido' : 'días seguidos'}',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              Text(
                'Récord $record',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Dia(
                    inicial: inicialesSemana[i],
                    estado: dias[i],
                    retraso: Duration(milliseconds: 250 + 70 * i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Ícono de la racha: se enciende con un rebote y un leve vaivén, y brilla
/// mientras la racha siga viva.
class _Llama extends StatelessWidget {
  const _Llama({required this.encendida});

  final bool encendida;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Progreso(
      duracion: const Duration(milliseconds: 900),
      curva: Curves.linear,
      builder: (context, t) {
        final escala = Curves.elasticOut.transform(t);
        // Vaivén que se apaga: como una llama que prende.
        final giro = math.sin(t * math.pi * 4) * 0.18 * (1 - t);
        return Transform.rotate(
          angle: giro,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: escala,
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (encendida)
                    BoxShadow(
                      color: colores.primary.withValues(alpha: 0.45 * t),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 20,
                color: encendida ? colores.primary : colores.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.inicial,
    required this.estado,
    required this.retraso,
  });

  final String inicial;
  final EstadoDia estado;

  /// Cuándo empieza su animación: cada día un poco después del anterior.
  final Duration retraso;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    const radio = BorderRadius.all(Radius.circular(7));

    final Widget cuadro = switch (estado) {
      // Se llena de abajo hacia arriba.
      EstadoDia.entrenado => ClipRRect(
        borderRadius: radio,
        child: ColoredBox(
          color: colores.primary.withValues(alpha: 0.12),
          child: Progreso(
            retraso: retraso,
            duracion: const Duration(milliseconds: 500),
            builder: (context, t) => Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: t,
                widthFactor: 1,
                child: ColoredBox(color: colores.primary),
              ),
            ),
          ),
        ),
      ),
      EstadoDia.descanso => Rebote(
        retraso: retraso,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colores.primary.withValues(alpha: 0.12),
            borderRadius: radio,
          ),
        ),
      ),
      EstadoDia.futuro => Rebote(
        retraso: retraso,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colores.outlineVariant),
            borderRadius: radio,
          ),
        ),
      ),
      // El borde punteado se dibuja trazo a trazo.
      EstadoDia.hoy => Progreso(
        retraso: retraso,
        duracion: const Duration(milliseconds: 700),
        builder: (context, t) => CustomPaint(
          painter: _BordePunteado(color: colores.onSurfaceVariant, progreso: t),
        ),
      ),
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
  _BordePunteado({required this.color, this.progreso = 1});

  final Color color;

  /// Fracción del borde ya dibujada (0 a 1).
  final double progreso;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final borde = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.6),
          const Radius.circular(7),
        ),
      );
    const trazo = 4.0;
    const hueco = 3.0;
    for (final PathMetric tramo in borde.computeMetrics()) {
      final hasta = tramo.length * progreso;
      for (var d = 0.0; d < hasta; d += trazo + hueco) {
        canvas.drawPath(tramo.extractPath(d, d + trazo), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado anterior) =>
      anterior.color != color || anterior.progreso != progreso;
}
