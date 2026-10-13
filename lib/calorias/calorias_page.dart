import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class CaloriasPage extends StatelessWidget {
  const CaloriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorías')),
      body: const PaginaEnConstruccion(nombre: 'Calorías'),
    );
  }
}
