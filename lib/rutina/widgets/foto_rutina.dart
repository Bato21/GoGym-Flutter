import 'package:flutter/material.dart';

/// Ícono según la categoría de la rutina.
IconData iconoCategoria(String categoria) => switch (categoria.toLowerCase()) {
  'cardio' => Icons.directions_run,
  'movilidad' || 'flexibilidad' || 'yoga' => Icons.self_improvement,
  'hiit' || 'funcional' => Icons.bolt,
  _ => Icons.fitness_center,
};

/// Portada de una rutina: franjas diagonales con el ícono de su categoría, como
/// el marcador "foto de la rutina" del mockup. Sirve tanto de miniatura en la
/// lista como de cabecera en el detalle (viaja entre ambas con un Hero).
class FotoRutina extends StatelessWidget {
  const FotoRutina({
    super.key,
    required this.categoria,
    this.radio = BorderRadius.zero,
    this.tamanoIcono = 22,
  });

  final String categoria;
  final BorderRadius radio;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: radio,
      child: CustomPaint(
        painter: _Franjas(
          fondo: colores.surfaceContainer,
          franja: colores.outlineVariant.withValues(alpha: 0.45),
        ),
        child: Center(
          child: Icon(
            iconoCategoria(categoria),
            size: tamanoIcono,
            color: colores.primary.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _Franjas extends CustomPainter {
  _Franjas({required this.fondo, required this.franja});

  final Color fondo;
  final Color franja;

  static const ancho = 7.0;
  static const hueco = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fondo);
    final pincel = Paint()
      ..color = franja
      ..strokeWidth = ancho;
    // Líneas a 45° que cubren todo el rectángulo.
    for (var x = -size.height; x < size.width; x += ancho + hueco) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_Franjas anterior) =>
      anterior.fondo != fondo || anterior.franja != franja;
}
