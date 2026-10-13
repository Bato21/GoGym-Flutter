import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class RutinaPage extends StatelessWidget {
  const RutinaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: const PaginaEnConstruccion(nombre: 'Rutinas'),
    );
  }
}
