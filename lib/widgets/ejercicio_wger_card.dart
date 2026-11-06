import 'package:flutter/material.dart';

import '../models/ejercicio_wger.dart';

/// Fila de la lista de wger: miniatura (con Hero hacia el detalle), nombre,
/// categoría y equipamiento.
class EjercicioWgerCard extends StatelessWidget {
  const EjercicioWgerCard({super.key, required this.ejercicio, this.onTap});

  final EjercicioWger ejercicio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final detalle = [
      ejercicio.categoria,
      if (ejercicio.equipamiento.isNotEmpty) ejercicio.equipamiento.join(', '),
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: Hero(
        tag: 'wger-${ejercicio.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: ImagenWger(url: ejercicio.imagen),
          ),
        ),
      ),
      title: Text(ejercicio.nombre),
      subtitle: Text(detalle),
      trailing: ejercicio.enEspanol
          ? null
          : const Tooltip(message: 'Solo en inglés', child: Text('EN')),
    );
  }
}

/// Imagen de wger con respaldo: sin URL o si no carga, un ícono.
/// Las fotos de wger suelen tener fondo blanco, así que se muestran sobre
/// blanco también en el tema oscuro.
class ImagenWger extends StatelessWidget {
  const ImagenWger({super.key, required this.url, this.tamanoIcono = 24});

  final String? url;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    final respaldo = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.fitness_center, size: tamanoIcono)),
    );
    if (url == null) return respaldo;
    return ColoredBox(
      color: Colors.white,
      child: Image.network(
        url!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => respaldo,
      ),
    );
  }
}
