import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calorias/calorias_page.dart';
import '../entrenamiento/entrenamiento_page.dart';
import '../inicio/inicio_page.dart';
import '../logros/logros_page.dart';
import '../perfil/perfil_page.dart';
import '../providers/navegacion_provider.dart';
import '../rutina/rutina_page.dart';
import '../widgets/barra_navegacion.dart';

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

  // Mismo orden que [Pestana].
  static const _destinos = [
    DestinoBarra(
      icono: Icons.home_outlined,
      iconoActivo: Icons.home_rounded,
      etiqueta: 'Inicio',
    ),
    DestinoBarra(
      icono: Icons.fitness_center_outlined,
      iconoActivo: Icons.fitness_center,
      etiqueta: 'Entrenar',
    ),
    DestinoBarra(
      icono: Icons.calendar_month_outlined,
      iconoActivo: Icons.calendar_month,
      etiqueta: 'Rutinas',
    ),
    DestinoBarra(
      icono: Icons.local_fire_department_outlined,
      iconoActivo: Icons.local_fire_department,
      etiqueta: 'Calorías',
    ),
    DestinoBarra(
      icono: Icons.emoji_events_outlined,
      iconoActivo: Icons.emoji_events,
      etiqueta: 'Logros',
    ),
    DestinoBarra(
      icono: Icons.person_outline,
      iconoActivo: Icons.person,
      etiqueta: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navegacion = context.watch<NavegacionProvider>();
    final indice = navegacion.actual.index;
    return Scaffold(
      // IndexedStack mantiene el estado de cada pestaña al cambiar,
      // igual que ion-tabs.
      body: IndexedStack(index: indice, children: _paginas),
      bottomNavigationBar: BarraNavegacion(
        destinos: _destinos,
        indice: indice,
        onTap: (i) => navegacion.irA(Pestana.values[i]),
      ),
    );
  }
}
