import 'package:flutter/material.dart';

import 'tarjeta.dart';

/// Un número grande con su etiqueta: "8.240 kg / Volumen".
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.valor,
    required this.etiqueta,
    this.unidad,
  });

  final String valor;
  final String etiqueta;
  final String? unidad;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: valor,
                children: [
                  if (unidad != null)
                    TextSpan(
                      text: ' $unidad',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              style: tema.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: tema.textTheme.labelSmall
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
