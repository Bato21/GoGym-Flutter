import 'package:flutter/material.dart';

import '../models/sesion.dart';
import '../utils/fechas.dart';
import '../utils/formato.dart';
import 'tarjeta.dart';

/// Una sesión de la lista: icono, título, detalle y una métrica a la derecha.
class SesionCard extends StatelessWidget {
  const SesionCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.metrica,
    this.onTap,
  });

  /// Tarjeta de un entrenamiento terminado, igual en Inicio y en el historial
  /// de Entrenamiento. Con pesas muestra el volumen; sin pesas, la quema
  /// estimada si se conoce el peso del usuario.
  factory SesionCard.desde(
    Sesion sesion, {
    Key? key,
    required DateTime hoy,
    double? pesoKg,
    VoidCallback? onTap,
  }) {
    final grupo = sesion.grupoPrincipal;
    final volumen = sesion.volumen;
    final conPesas = volumen > 0;
    return SesionCard(
      key: key,
      icono: conPesas ? Icons.fitness_center : Icons.directions_run,
      titulo: grupo == null || sesion.nombre.contains(grupo)
          ? sesion.nombre
          : '${sesion.nombre} · $grupo',
      detalle:
          '${diaRelativo(sesion.inicio, hoy)} · ${formatearTiempo(sesion.duracion)}',
      metrica: conPesas
          ? '${formatearMiles(volumen)} kg'
          : pesoKg == null
          ? '${sesion.totalSeries} series'
          : '${formatearMiles(sesion.kcalEstimadas(pesoKg))} kcal',
      onTap: onTap,
    );
  }

  final IconData icono;
  final String titulo;
  final String detalle;
  final String metrica;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Tarjeta(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colores.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: colores.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            metrica,
            style: tema.textTheme.bodySmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
