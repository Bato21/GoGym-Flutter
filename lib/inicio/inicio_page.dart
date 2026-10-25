import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/perfil.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/navegacion_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/rutinas_provider.dart';
import '../utils/fechas.dart';
import '../utils/formato.dart';
import '../widgets/aparecer.dart';
import '../widgets/cerrar_sesion.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/sesion_card.dart';
import '../widgets/stat_card.dart';
import 'widgets/animaciones.dart';
import 'widgets/racha_card.dart';
import 'widgets/rutina_hoy_card.dart';

/// Dashboard: racha, totales de la semana, la rutina que toca y las últimas
/// sesiones. Todo sale de los providers de la cuenta.
/// Cada vez que se entra a la pestaña, las secciones llegan en cascada y los
/// números cuentan hasta su valor.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key, this.ahora = DateTime.now, this.onCerrarSesion});

  /// Reloj inyectable para las pruebas.
  final DateTime Function() ahora;
  final Future<void> Function()? onCerrarSesion;

  /// Cuántas sesiones muestra la lista.
  static const cantidadUltimas = 3;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  /// Sube al volver a la pestaña: las secciones llevan una key con este
  /// número, así se reconstruyen y sus animaciones se repiten.
  int _visita = 0;
  Pestana? _pestanaAnterior;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final actual = context.watch<NavegacionProvider>().actual;
    if (actual == Pestana.inicio && _pestanaAnterior != Pestana.inicio) {
      _visita++;
    }
    _pestanaAnterior = actual;
  }

  /// Sección número [indice] de la cascada.
  Widget _seccion(
    int indice,
    Widget hijo, {
    Offset desde = const Offset(0, 24),
  }) => Aparecer(
    key: ValueKey('seccion-$indice-$_visita'),
    indice: indice,
    desde: desde,
    child: hijo,
  );

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>().perfil;
    final rutinas = context.watch<RutinasProvider>();
    final entrenamientos = context.watch<EntrenamientosProvider>();
    final navegacion = context.read<NavegacionProvider>();
    final hoy = widget.ahora();

    final semana = entrenamientos.deLaSemana(hoy);
    final volumenSemana = semana.fold(0.0, (suma, s) => suma + s.volumen);
    final tiempoSemana = semana.fold(
      Duration.zero,
      (suma, s) => suma + s.duracion,
    );
    final ultimas = entrenamientos.ultimas(InicioPage.cantidadUltimas);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _recargar(context),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _seccion(
                0,
                desde: const Offset(-24, 0),
                _Encabezado(
                  fecha: fechaLarga(hoy),
                  nombre: perfil?.nombre ?? '',
                  iniciales: perfil?.iniciales ?? '',
                  onVerPerfil: () => navegacion.irA(Pestana.perfil),
                  onCerrarSesion: widget.onCerrarSesion,
                ),
              ),
              const SizedBox(height: 16),
              _seccion(
                1,
                RachaCard(
                  actual: entrenamientos.rachaActual(hoy),
                  record: entrenamientos.rachaRecord,
                  dias: _estadosSemana(entrenamientos.diasDeLaSemana(hoy), hoy),
                ),
              ),
              const SizedBox(height: 16),
              _seccion(2, const _TituloSeccion(texto: 'Esta semana')),
              const SizedBox(height: 8),
              _seccion(
                3,
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: NumeroAnimado(
                          valor: semana.length.toDouble(),
                          builder: (context, v) => StatCard(
                            valor: '${v.round()}',
                            etiqueta: 'Sesiones',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NumeroAnimado(
                          valor: volumenSemana,
                          builder: (context, v) => StatCard(
                            valor: formatearMiles(v),
                            unidad: 'kg',
                            etiqueta: 'Volumen',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NumeroAnimado(
                          valor: tiempoSemana.inSeconds.toDouble(),
                          builder: (context, v) => StatCard(
                            valor: formatearTiempo(
                              Duration(seconds: v.round()),
                            ),
                            etiqueta: 'Tiempo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _seccion(
                4,
                // Si cambia la rutina que toca (p. ej. al terminar un
                // entrenamiento), la tarjeta se reemplaza deslizándose.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (hijo, animacion) => FadeTransition(
                    opacity: animacion,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animacion),
                      child: hijo,
                    ),
                  ),
                  child: _rutinaHoy(
                    rutina: rutinas.siguiente(entrenamientos.historial),
                    perfil: perfil,
                    entrenoHoy: entrenamientos.entrenoEl(hoy),
                    hoy: hoy,
                    navegacion: navegacion,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _seccion(
                5,
                _TituloSeccion(
                  texto: 'Últimas sesiones',
                  accion: 'Ver todas',
                  onAccion: () => navegacion.irA(Pestana.entrenamiento),
                ),
              ),
              const SizedBox(height: 4),
              if (ultimas.isEmpty)
                _seccion(6, const _SinSesiones())
              else
                for (final (i, sesion) in ultimas.indexed)
                  _seccion(
                    6 + i,
                    desde: const Offset(48, 0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PressableScale(
                        child: _sesionCard(sesion, perfil, hoy, navegacion),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recargar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await Future.wait([
        context.read<PerfilProvider>().recargar(),
        context.read<RutinasProvider>().recargar(),
        context.read<EntrenamientosProvider>().recargar(),
      ]);
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar. Revisa tu conexión.'),
        ),
      );
    }
  }

  static List<EstadoDia> _estadosSemana(List<bool> entrenados, DateTime hoy) {
    final indiceHoy = indiceDia(hoy);
    return [
      for (var i = 0; i < 7; i++)
        if (entrenados[i])
          EstadoDia.entrenado
        else if (i == indiceHoy)
          EstadoDia.hoy
        else if (i < indiceHoy)
          EstadoDia.descanso
        else
          EstadoDia.futuro,
    ];
  }

  static Widget _rutinaHoy({
    required Rutina? rutina,
    required Perfil? perfil,
    required bool entrenoHoy,
    required DateTime hoy,
    required NavegacionProvider navegacion,
  }) {
    if (rutina == null) {
      return RutinaHoyCard(
        key: const ValueKey('sin-rutina'),
        etiqueta: 'Sin rutinas',
        titulo: 'Arma tu primera rutina',
        detalle: 'Elige ejercicios y empieza a entrenar.',
        textoBoton: 'Crear',
        onPressed: () => navegacion.irA(Pestana.rutina),
      );
    }
    return RutinaHoyCard(
      key: ValueKey('rutina-${rutina.id}'),
      etiqueta: _etiquetaRutinaHoy(perfil, entrenoHoy, hoy),
      titulo: _tituloRutina(rutina),
      detalle: [
        '${rutina.ejercicios.length} '
            '${rutina.ejercicios.length == 1 ? 'ejercicio' : 'ejercicios'}',
        if (rutina.minutos > 0) '${rutina.minutos} min',
        if (rutina.nivel.isNotEmpty) rutina.nivel,
      ].join(' · '),
      textoBoton: 'Empezar',
      onPressed: () => navegacion.irA(Pestana.entrenamiento),
    );
  }

  /// "Toca hoy", "Hoy ya entrenaste · Próxima" o el próximo día de entrenamiento.
  static String _etiquetaRutinaHoy(
    Perfil? perfil,
    bool entrenoHoy,
    DateTime hoy,
  ) {
    if (entrenoHoy) return 'Hoy ya entrenaste · Próxima';
    if (perfil == null) return 'Siguiente rutina';
    if (perfil.esDiaEntrenamiento(hoy)) return 'Toca hoy';
    final proximo = perfil.proximoDiaEntrenamiento(hoy);
    return proximo == null
        ? 'Siguiente rutina'
        : 'Próximo entreno · ${nombreDia(proximo)}';
  }

  /// "Push A · Pecho y hombro": nombre y los dos primeros grupos musculares.
  static String _tituloRutina(Rutina rutina) {
    final grupos = rutina.grupos.take(2).toList();
    final detalle = grupos.isEmpty
        ? rutina.categoria
        : [
            grupos.first,
            ...grupos.skip(1).map((g) => g.toLowerCase()),
          ].join(' y ');
    return detalle.isEmpty ? rutina.nombre : '${rutina.nombre} · $detalle';
  }

  static Widget _sesionCard(
    Sesion sesion,
    Perfil? perfil,
    DateTime hoy,
    NavegacionProvider navegacion,
  ) {
    final grupo = sesion.grupoPrincipal;
    final volumen = sesion.volumen;
    final conPesas = volumen > 0;
    return SesionCard(
      icono: conPesas ? Icons.fitness_center : Icons.directions_run,
      titulo: grupo == null || sesion.nombre.contains(grupo)
          ? sesion.nombre
          : '${sesion.nombre} · $grupo',
      detalle:
          '${diaRelativo(sesion.inicio, hoy)} · ${formatearTiempo(sesion.duracion)}',
      metrica: conPesas
          ? '${formatearMiles(volumen)} kg'
          : perfil == null
          ? '${sesion.totalSeries} series'
          : '${formatearMiles(sesion.kcalEstimadas(perfil.pesoKg))} kcal',
      onTap: () => navegacion.irA(Pestana.entrenamiento),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.fecha,
    required this.nombre,
    required this.iniciales,
    required this.onVerPerfil,
    required this.onCerrarSesion,
  });

  final String fecha;
  final String nombre;
  final String iniciales;
  final VoidCallback onVerPerfil;
  final Future<void> Function()? onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fecha,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                style: tema.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Rebote(
          retraso: const Duration(milliseconds: 250),
          duracion: const Duration(milliseconds: 650),
          child: PopupMenuButton<_AccionCuenta>(
            key: const Key('menu-avatar'),
            tooltip: 'Abrir menú de cuenta',
            offset: const Offset(0, 8),
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (accion) async {
              switch (accion) {
                case _AccionCuenta.verPerfil:
                  onVerPerfil();
                  return;
                case _AccionCuenta.cerrarSesion:
                  final cerrar = onCerrarSesion;
                  if (cerrar != null) {
                    await confirmarCierreSesion(context, cerrar);
                  }
                  return;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                key: Key('menu-ver-perfil'),
                value: _AccionCuenta.verPerfil,
                child: _OpcionCuenta(
                  icono: Icons.person_outline_rounded,
                  texto: 'Ver perfil',
                ),
              ),
              if (onCerrarSesion != null) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  key: const Key('menu-cerrar-sesion'),
                  value: _AccionCuenta.cerrarSesion,
                  child: _OpcionCuenta(
                    icono: Icons.logout_rounded,
                    texto: 'Cerrar sesión',
                    color: colores.error,
                  ),
                ),
              ],
            ],
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colores.primary.withValues(alpha: 0.15),
                border: Border.all(color: colores.primary, width: 1.5),
              ),
              child: iniciales.isEmpty
                  ? Icon(Icons.person, size: 20, color: colores.primary)
                  : Text(
                      iniciales,
                      style: tema.textTheme.labelLarge?.copyWith(
                        color: colores.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _AccionCuenta { verPerfil, cerrarSesion }

class _OpcionCuenta extends StatelessWidget {
  const _OpcionCuenta({required this.icono, required this.texto, this.color});

  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorFinal = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icono, color: colorFinal, size: 20),
        const SizedBox(width: 12),
        Text(
          texto,
          style: TextStyle(color: colorFinal, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Título de sección en versalitas, con una acción opcional a la derecha.
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.texto, this.accion, this.onAccion});

  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            texto.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (accion != null)
          TextButton(
            onPressed: onAccion,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: tema.textTheme.labelMedium,
            ),
            child: Text(accion!),
          ),
      ],
    );
  }
}

class _SinSesiones extends StatelessWidget {
  const _SinSesiones();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Aún no terminas ningún entrenamiento.',
        textAlign: TextAlign.center,
        style: tema.textTheme.bodyMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
