import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_gym/data/datos_repositorio.dart';
import 'package:go_gym/inicio/inicio_page.dart';
import 'package:go_gym/models/perfil.dart';
import 'package:go_gym/models/rutina.dart';
import 'package:go_gym/models/sesion.dart';
import 'package:go_gym/providers/entrenamientos_provider.dart';
import 'package:go_gym/providers/navegacion_provider.dart';
import 'package:go_gym/providers/perfil_provider.dart';
import 'package:go_gym/providers/rutinas_provider.dart';
import 'package:go_gym/tabs/tabs_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'repositorio_falso.dart';

/// Miércoles 14 de octubre de 2026, 18:00.
final hoy = DateTime(2026, 10, 14, 18);

RepositorioFalso repositorioConDatos() => RepositorioFalso(
      perfilGuardado: const Perfil(
        nombre: 'Vicente',
        apellido: 'Rodríguez',
        objetivo: '',
        pesoKg: 80,
        diasEntrenamiento: [0, 2, 4],
        horaEntrenamiento: '18:00',
        metaCalorias: 2200,
      ),
      rutinasGuardadas: [
        Rutina(
          id: 1,
          nombre: 'Push A',
          categoria: 'Fuerza',
          nivel: 'Intermedio',
          minutos: 55,
          ejercicios: [
            ejercicio(11, 'Pecho'),
            ejercicio(12, 'Pecho'),
            ejercicio(13, 'Hombro'),
          ],
        ),
        Rutina(
          id: 2,
          nombre: 'Pull B',
          categoria: 'Fuerza',
          nivel: '',
          minutos: 50,
          ejercicios: [ejercicio(21, 'Espalda')],
        ),
        Rutina(
          id: 3,
          nombre: 'Legs A',
          categoria: 'Fuerza',
          nivel: '',
          minutos: 60,
          ejercicios: [ejercicio(31, 'Pierna')],
        ),
      ],
      sesionesGuardadas: [
        // Semana pasada: 4 días seguidos (récord).
        for (var d = 1; d <= 4; d++)
          sesion('Push A', DateTime(2026, 10, d, 9), 50, rutinaId: 1),
        sesion('Pull B', DateTime(2026, 10, 11, 9), 52, rutinaId: 2),
        sesion('Cinta', DateTime(2026, 10, 12, 19), 28, ejercicios: [
          ejercicioSesion('Cardio', const [Serie(reps: 1)], met: 7),
        ]),
        sesion('Legs A', DateTime(2026, 10, 13, 10), 61, rutinaId: 3,
            ejercicios: [
              ejercicioSesion('Pierna', const [
                Serie(kg: 80, reps: 5),
                Serie(kg: 80, reps: 5),
                Serie(kg: 80, reps: 5),
                Serie(kg: 60, reps: 10),
                Serie(kg: 60, reps: 10),
              ]),
            ]),
      ],
    );

/// Carga los providers como lo hace AuthGate y monta [hijo] encima.
Future<NavegacionProvider> montar(
  WidgetTester tester,
  RepositorioFalso repositorio,
  Widget hijo,
) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final perfil = PerfilProvider(repositorio);
  final rutinas = RutinasProvider(repositorio);
  final entrenamientos = EntrenamientosProvider(repositorio);
  final navegacion = NavegacionProvider();
  await Future.wait([
    perfil.cargar('u1', nombre: 'Nuevo'),
    rutinas.cargar('u1'),
    entrenamientos.cargar('u1'),
  ]);

  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<DatosRepositorio>.value(value: repositorio),
      ChangeNotifierProvider.value(value: perfil),
      ChangeNotifierProvider.value(value: rutinas),
      ChangeNotifierProvider.value(value: entrenamientos),
      ChangeNotifierProvider.value(value: navegacion),
    ],
    child: MaterialApp(home: hijo),
  ));
  return navegacion;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('Inicio muestra todo calculado desde los datos de la cuenta',
      (tester) async {
    await montar(tester, repositorioConDatos(), InicioPage(ahora: () => hoy));

    // Encabezado.
    expect(find.text('Miércoles 14 de octubre'), findsOneWidget);
    expect(find.text('Hola, Vicente'), findsOneWidget);
    expect(find.text('VR'), findsOneWidget);

    // Racha: hoy (mié) no entrenó, sigue viva desde ayer: mar, lun, dom.
    expect(find.text('3 días seguidos'), findsOneWidget);
    expect(find.text('Récord 4'), findsOneWidget);

    // Semana (lun 12 – dom 18): Cinta + Legs A.
    expect(find.text('2'), findsOneWidget);
    // Volumen de la semana y el de Legs A coinciden: solo Legs A usó pesas.
    expect(find.text('2.400 kg'), findsNWidgets(2));
    expect(find.text('1h 29'), findsOneWidget);

    // Rotación: tras Legs A viene Push A; el miércoles es día de entrenamiento.
    expect(find.text('TOCA HOY'), findsOneWidget);
    expect(find.text('Push A · Pecho y hombro'), findsOneWidget);
    expect(find.text('3 ejercicios · 55 min · Intermedio'), findsOneWidget);

    // Últimas 3, la más reciente primero.
    expect(find.text('Legs A · Pierna'), findsOneWidget);
    expect(find.text('Ayer · 1h 01'), findsOneWidget);
    expect(find.text('Cinta · Cardio'), findsOneWidget);
    expect(find.text('Lunes · 28 min'), findsOneWidget);
    expect(find.text('261 kcal'), findsOneWidget); // 7 MET × 80 kg × 28/60 h
    expect(find.text('Pull B · Espalda'), findsNothing); // sin ejercicios
    expect(find.text('Pull B'), findsOneWidget);
    expect(find.text('Domingo · 52 min'), findsOneWidget);
  });

  testWidgets('Inicio sin datos muestra estados vacíos', (tester) async {
    final navegacion = await montar(
        tester, RepositorioFalso(), InicioPage(ahora: () => hoy));

    // Cuenta nueva: el perfil se crea con el nombre del registro.
    expect(find.text('Hola, Nuevo'), findsOneWidget);
    expect(find.text('0 días seguidos'), findsOneWidget);
    expect(find.text('Récord 0'), findsOneWidget);
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('Arma tu primera rutina'), findsOneWidget);
    expect(find.text('Aún no terminas ningún entrenamiento.'), findsOneWidget);

    await tester.tap(find.text('Crear'));
    expect(navegacion.actual, Pestana.rutina);
  });

  testWidgets('Los accesos de Inicio cambian de pestaña', (tester) async {
    final navegacion =
        await montar(tester, repositorioConDatos(), const TabsPage());

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(navegacion.actual, Pestana.entrenamiento);

    navegacion.irA(Pestana.inicio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('VR'));
    await tester.pumpAndSettle();
    expect(navegacion.actual, Pestana.perfil);
    expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
  });
}
