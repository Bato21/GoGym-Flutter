import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calorias/calorias_page.dart';
import '../entrenamiento/entrenamiento_page.dart';
import '../inicio/inicio_page.dart';
import '../logros/logros_page.dart';
import '../perfil/perfil_page.dart';
import '../providers/navegacion_provider.dart';
import '../rutina/rutina_page.dart';

/// Barra de pestañas inferior. Equivalente a `src/app/tabs` en Ionic.
/// La pestaña activa vive en [NavegacionProvider], así una vista puede abrir otra.
class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  // Mismo orden que [Pestana].
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
    final navegacion = context.watch<NavegacionProvider>();
    final indice = navegacion.actual.index;
    return Scaffold(
      // IndexedStack mantiene el estado de cada pestaña al cambiar,
      // igual que ion-tabs.
      body: IndexedStack(index: indice, children: _paginas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indice,
        onTap: (i) => navegacion.irA(Pestana.values[i]),
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
