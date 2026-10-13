import 'package:flutter/material.dart';

import '../widgets/pagina_en_construccion.dart';

class LogrosPage extends StatelessWidget {
  const LogrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: const PaginaEnConstruccion(nombre: 'Logros'),
    );
  }
}
