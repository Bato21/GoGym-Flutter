import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: const PaginaEnConstruccion(nombre: 'Inicio'),
    );
  }
}
