import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_repositorio.dart';
import '../models/ejercicio_catalogo.dart';

/// Catálogo de ejercicios traído desde Supabase.
class BibliotecaPage extends StatefulWidget {
  const BibliotecaPage({super.key});

  @override
  State<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends State<BibliotecaPage> {
  late final Future<List<EjercicioCatalogo>> _catalogo;

  @override
  void initState() {
    super.initState();
    _catalogo = context.read<DatosRepositorio>().catalogoEjercicios();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EjercicioCatalogo>>(
      future: _catalogo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final ejercicios = snapshot.requireData;
        return ListView.builder(
          itemCount: ejercicios.length,
          itemBuilder: (context, index) {
            final ejercicio = ejercicios[index];
            return ListTile(
              title: Text(ejercicio.nombre),
              subtitle: Text(ejercicio.grupo),
            );
          },
        );
      },
    );
  }
}