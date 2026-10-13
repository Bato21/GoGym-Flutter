import 'package:flutter/material.dart';

/// Contenido temporal para las pestañas que aún no se implementan.
/// Equivalente a `explore-container` en Ionic. Reemplazar al construir cada vista.
class PaginaEnConstruccion extends StatelessWidget {
  const PaginaEnConstruccion({super.key, required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$nombre: en construcción',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
