import 'package:flutter/material.dart';

import '../models/ejercicio_catalogo.dart';

/// Fila del catálogo: miniatura (con Hero hacia el detalle), nombre,
/// equipo y músculos. Quien la usa decide qué pasa al tocarla.
class EjercicioCard extends StatelessWidget {
  const EjercicioCard({super.key, required this.ejercicio, this.onTap});

  final EjercicioCatalogo ejercicio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Imagen de RepDB si existe; si no hay o no carga, un ícono.
    // Tamaño fijo para que la fila no salte al cargar la imagen.
    return ListTile(
      onTap: onTap,
      leading: Hero(
        tag: 'imagen-${ejercicio.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: ejercicio.urlImagen == null
                ? const Icon(Icons.fitness_center)
                : Image.network(
                    ejercicio.urlImagen!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.fitness_center),
                  ),
          ),
        ),
      ),
      title: Text(ejercicio.nombre),
      subtitle: Text('${ejercicio.equipo} · ${ejercicio.musculos.join(', ')}'),
    );
  }
}
