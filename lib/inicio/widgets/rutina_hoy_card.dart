import 'package:flutter/material.dart';

import '../../widgets/tarjeta.dart';

/// Tarjeta destacada con la rutina que toca y un botón para empezarla.
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
    return Tarjeta(
      destacada: true,
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
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: colores.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colores.primary,
              side: BorderSide(color: colores.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(textoBoton),
          ),
        ],
      ),
    );
  }
}
