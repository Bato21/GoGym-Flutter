import 'package:flutter/material.dart';

import '../calorias/calorias_page.dart';
import '../entrenamiento/entrenamiento_page.dart';
import '../inicio/inicio_page.dart';
import '../logros/logros_page.dart';
import '../perfil/perfil_page.dart';
import '../rutina/rutina_page.dart';

/// Barra de pestañas inferior. Equivalente a `src/app/tabs` en Ionic.
class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _indice = 0;

  static const _paginas = <Widget>[
    InicioPage(),
    EntrenamientoPage(),
    RutinaPage(),
    CaloriasPage(),
    LogrosPage(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pestaña al cambiar,
      // igual que ion-tabs.
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Entrenamiento'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Rutina'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department), label: 'Calorías'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Logros'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
