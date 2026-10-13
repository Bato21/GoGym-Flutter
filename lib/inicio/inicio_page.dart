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
import '../widgets/sesion_card.dart';
import '../widgets/stat_card.dart';
import 'widgets/racha_card.dart';
import 'widgets/rutina_hoy_card.dart';

/// Dashboard: racha, totales de la semana, la rutina que toca y las últimas
/// sesiones. Todo sale de los providers de la cuenta.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key, this.ahora = DateTime.now});

  /// Reloj inyectable para las pruebas.
  final DateTime Function() ahora;

  /// Cuántas sesiones muestra la lista.
  static const cantidadUltimas = 3;

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>().perfil;
    final rutinas = context.watch<RutinasProvider>();
    final entrenamientos = context.watch<EntrenamientosProvider>();
    final navegacion = context.read<NavegacionProvider>();
    final hoy = ahora();

    final semana = entrenamientos.deLaSemana(hoy);
    final volumenSemana = semana.fold(0.0, (suma, s) => suma + s.volumen);
    final tiempoSemana =
        semana.fold(Duration.zero, (suma, s) => suma + s.duracion);
    final ultimas = entrenamientos.ultimas(cantidadUltimas);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _recargar(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Encabezado(
                fecha: fechaLarga(hoy),
                nombre: perfil?.nombre ?? '',
                iniciales: perfil?.iniciales ?? '',
                onAvatar: () => navegacion.irA(Pestana.perfil),
              ),
              const SizedBox(height: 16),
              RachaCard(
                actual: entrenamientos.rachaActual(hoy),
                record: entrenamientos.rachaRecord,
                dias: _estadosSemana(entrenamientos.diasDeLaSemana(hoy), hoy),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard(
                          valor: '${semana.length}', etiqueta: 'Sesiones'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        valor: formatearMiles(volumenSemana),
                        unidad: 'kg',
                        etiqueta: 'Volumen',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        valor: formatearTiempo(tiempoSemana),
                        etiqueta: 'Tiempo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _rutinaHoy(
                rutina: rutinas.siguiente(entrenamientos.historial),
                perfil: perfil,
                entrenoHoy: entrenamientos.entrenoEl(hoy),
                hoy: hoy,
                navegacion: navegacion,
              ),
              const SizedBox(height: 20),
              _TituloSeccion(
                texto: 'Últimas sesiones',
                accion: 'Ver todas',
                onAccion: () => navegacion.irA(Pestana.entrenamiento),
              ),
              const SizedBox(height: 4),
              if (ultimas.isEmpty)
                const _SinSesiones()
              else
                for (final sesion in ultimas) ...[
                  _sesionCard(sesion, perfil, hoy, navegacion),
                  const SizedBox(height: 8),
                ],
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
      mensajero.showSnackBar(const SnackBar(
          content: Text('No se pudo actualizar. Revisa tu conexión.')));
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

  Widget _rutinaHoy({
    required Rutina? rutina,
    required Perfil? perfil,
    required bool entrenoHoy,
    required DateTime hoy,
    required NavegacionProvider navegacion,
  }) {
    if (rutina == null) {
      return RutinaHoyCard(
        etiqueta: 'Sin rutinas',
        titulo: 'Arma tu primera rutina',
        detalle: 'Elige ejercicios y empieza a entrenar.',
        textoBoton: 'Crear',
        onPressed: () => navegacion.irA(Pestana.rutina),
      );
    }
    return RutinaHoyCard(
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
  static String _etiquetaRutinaHoy(Perfil? perfil, bool entrenoHoy, DateTime hoy) {
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
        : [grupos.first, ...grupos.skip(1).map((g) => g.toLowerCase())]
            .join(' y ');
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
    required this.onAvatar,
  });

  final String fecha;
  final String nombre;
  final String iniciales;
  final VoidCallback onAvatar;

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
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: colores.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                style: tema.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Ir a mi perfil',
          child: InkWell(
            onTap: onAvatar,
            customBorder: const CircleBorder(),
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

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.texto,
    required this.accion,
    required this.onAccion,
  });

  final String texto;
  final String accion;
  final VoidCallback onAccion;

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
        TextButton(
          onPressed: onAccion,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            textStyle: tema.textTheme.labelMedium,
          ),
          child: Text(accion),
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
        style: tema.textTheme.bodyMedium
            ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
