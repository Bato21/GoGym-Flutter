import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_gym/data/datos_repositorio.dart';
import 'package:go_gym/inicio/inicio_page.dart';
import 'package:go_gym/logros/logros_page.dart';
import 'package:go_gym/models/perfil.dart';
import 'package:go_gym/models/rutina.dart';
import 'package:go_gym/models/sesion.dart';
import 'package:go_gym/providers/entrenamientos_provider.dart';
import 'package:go_gym/providers/navegacion_provider.dart';
import 'package:go_gym/providers/perfil_provider.dart';
import 'package:go_gym/providers/rutinas_provider.dart';
import 'package:go_gym/perfil/perfil_page.dart';
import 'package:go_gym/rutina/rutina_page.dart';
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
    sesion(
      'Cinta',
      DateTime(2026, 10, 12, 19),
      28,
      ejercicios: [
        ejercicioSesion('Cardio', const [Serie(reps: 1)], met: 7),
      ],
    ),
    sesion(
      'Legs A',
      DateTime(2026, 10, 13, 10),
      61,
      rutinaId: 3,
      ejercicios: [
        ejercicioSesion('Pierna', const [
          Serie(kg: 80, reps: 5),
          Serie(kg: 80, reps: 5),
          Serie(kg: 80, reps: 5),
          Serie(kg: 60, reps: 10),
          Serie(kg: 60, reps: 10),
        ]),
      ],
    ),
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

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<DatosRepositorio>.value(value: repositorio),
        ChangeNotifierProvider.value(value: perfil),
        ChangeNotifierProvider.value(value: rutinas),
        ChangeNotifierProvider.value(value: entrenamientos),
        ChangeNotifierProvider.value(value: navegacion),
      ],
      child: MaterialApp(home: hijo),
    ),
  );
  return navegacion;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('Inicio muestra todo calculado desde los datos de la cuenta', (
    tester,
  ) async {
    await montar(tester, repositorioConDatos(), InicioPage(ahora: () => hoy));
    // Deja terminar las animaciones: los números cuentan desde 0.
    await tester.pumpAndSettle();

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
      tester,
      RepositorioFalso(),
      InicioPage(ahora: () => hoy),
    );
    await tester.pumpAndSettle();

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
    final navegacion = await montar(
      tester,
      repositorioConDatos(),
      const TabsPage(),
    );

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(navegacion.actual, Pestana.entrenamiento);

    navegacion.irA(Pestana.inicio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('VR'));
    await tester.pumpAndSettle();
    expect(find.text('Ver perfil'), findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-ver-perfil')));
    await tester.pumpAndSettle();
    expect(navegacion.actual, Pestana.perfil);
    expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
  });

  testWidgets('El menú del avatar permite cerrar sesión', (tester) async {
    var cierres = 0;
    await montar(
      tester,
      repositorioConDatos(),
      TabsPage(onCerrarSesion: () async => cierres++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('menu-avatar')));
    await tester.pumpAndSettle();
    expect(find.text('Ver perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-cerrar-sesion')));
    await tester.pumpAndSettle();
    expect(cierres, 0);

    await tester.tap(find.byKey(const Key('confirmar-cerrar-sesion')));
    await tester.pumpAndSettle();
    expect(cierres, 1);
  });

  testWidgets('Logros calcula desbloqueos y avances desde el historial', (
    tester,
  ) async {
    await montar(tester, repositorioConDatos(), LogrosPage(ahora: () => hoy));
    await tester.pumpAndSettle();

    expect(find.text('2 de 6 desbloqueados'), findsOneWidget);
    expect(
      find.textContaining('3 días de racha', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Récord 4', findRichText: true), findsOneWidget);
    expect(find.text('Primer entrenamiento'), findsOneWidget);
    expect(find.text('7/10'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.text('Constancia'));
    await tester.pumpAndSettle();
    expect(find.text('SIGUE AVANZANDO'), findsOneWidget);
    expect(find.textContaining('Te faltan 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cerrar-logro')));
    await tester.pumpAndSettle();
    expect(find.text('SIGUE AVANZANDO'), findsNothing);
  });

  testWidgets('Perfil muestra agenda y permite guardar cambios', (
    tester,
  ) async {
    final repositorio = repositorioConDatos();
    await montar(tester, repositorio, PerfilPage(ahora: () => hoy));
    await tester.pumpAndSettle();

    expect(find.text('Vicente Rodríguez'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Viernes 16'), findsOneWidget);
    expect(find.text('Lunes 19'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('editar-perfil')));
    await tester.tap(find.byKey(const Key('editar-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Editar perfil'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('campo-objetivo')),
      'Ganar masa muscular',
    );
    await tester.tap(find.byKey(const Key('guardar-perfil')));
    await tester.pumpAndSettle();

    expect(repositorio.perfilGuardado?.objetivo, 'Ganar masa muscular');
    expect(find.text('Perfil actualizado'), findsOneWidget);
  });

  testWidgets('Perfil pide confirmación antes de cerrar sesión', (
    tester,
  ) async {
    var cierres = 0;
    await montar(
      tester,
      repositorioConDatos(),
      PerfilPage(ahora: () => hoy, onCerrarSesion: () async => cierres++),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('cerrar-sesion')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('cerrar-sesion')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '¿Quieres salir de tu cuenta? Tendrás que iniciar sesión nuevamente.',
      ),
      findsOneWidget,
    );
    expect(cierres, 0);

    await tester.tap(find.byKey(const Key('confirmar-cerrar-sesion')));
    await tester.pumpAndSettle();
    expect(cierres, 1);
  });

  testWidgets('Rutinas lista, abre el detalle y empieza la rutina', (
    tester,
  ) async {
    final navegacion = await montar(
      tester,
      repositorioConDatos(),
      const RutinaPage(),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 rutinas · rotan en orden'), findsOneWidget);
    // Tras Legs A toca Push A.
    expect(find.text('FUERZA · SIGUIENTE'), findsOneWidget);
    expect(find.text('Pull B'), findsOneWidget);
    expect(find.text('Legs A'), findsOneWidget);
    expect(find.text('3 ejercicios · 55 min · Intermedio'), findsOneWidget);

    await tester.tap(find.text('Push A'));
    await tester.pumpAndSettle();

    // Detalle: cabecera, grupos y ejercicios como en el mockup.
    expect(find.text('RUTINA · FUERZA'), findsOneWidget);
    expect(find.text('Pecho'), findsOneWidget);
    expect(find.text('Hombro'), findsOneWidget);
    expect(find.text('EJERCICIOS'), findsOneWidget);
    expect(find.text('3 × 10 · 20 kg'), findsNWidgets(3));

    // Al tocar un ejercicio se despliegan sus series y el descanso.
    expect(find.text('Descanso 1:00'), findsNothing);
    await tester.tap(find.text('Ejercicio 11'));
    await tester.pumpAndSettle();
    expect(find.text('Descanso 1:00'), findsOneWidget);
    expect(find.text('S3'), findsOneWidget);

    await tester.tap(find.text('Empezar rutina'));
    await tester.pumpAndSettle();
    expect(navegacion.actual, Pestana.entrenamiento);
    expect(find.text('EJERCICIOS'), findsNothing);
  });

  testWidgets('Rutinas sin datos muestra el estado vacío', (tester) async {
    await montar(tester, RepositorioFalso(), const RutinaPage());
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes rutinas'), findsOneWidget);
  });

  test('Reordenar ejercicios cambia la rutina y la guarda', () async {
    final repositorio = repositorioConDatos();
    final rutinas = RutinasProvider(repositorio);
    await rutinas.cargar('u1');

    await rutinas.reordenar(1, 0, 2);

    final ids = [for (final e in rutinas.rutinas.first.ejercicios) e.id];
    expect(ids, [12, 13, 11]);
    expect([for (final e in repositorio.ejerciciosGuardados[1]!) e.id], ids);
    expect(rutinas.rutinas.first.ejercicios.first.toJson()['id'], 12);
  });
}
