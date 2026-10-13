import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class EntrenamientoPage extends StatelessWidget {
  const EntrenamientoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: const PaginaEnConstruccion(nombre: 'Entrenamiento'),
    );
  }
}
