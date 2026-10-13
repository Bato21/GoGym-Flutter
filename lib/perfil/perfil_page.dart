import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const PaginaEnConstruccion(nombre: 'Perfil'),
    );
  }
}
