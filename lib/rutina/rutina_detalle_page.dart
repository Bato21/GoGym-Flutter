import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rutina.dart';
import '../providers/navegacion_provider.dart';
import '../providers/rutinas_provider.dart';
import '../widgets/aparecer.dart';
import '../widgets/pressable_scale.dart';
import 'widgets/ejercicio_rutina_card.dart';
import 'widgets/foto_rutina.dart';
import 'widgets/rutina_card.dart';

/// Detalle de una rutina (vista 03 del mockup): portada, grupos musculares,
/// ejercicios que se pueden desplegar y reordenar, y el botón para empezarla.
/// Recibe la rutina por constructor y luego la sigue en [RutinasProvider],
/// así un cambio de orden se ve al instante.
class RutinaDetallePage extends StatefulWidget {
  const RutinaDetallePage({super.key, required this.rutina});

  final Rutina rutina;

  @override
  State<RutinaDetallePage> createState() => _RutinaDetallePageState();
}

class _RutinaDetallePageState extends State<RutinaDetallePage> {
  /// Grupo resaltado con los chips; null = ninguno.
  String? _grupo;

  /// Ejercicio desplegado, por id.
  int? _expandido;

  static const _altoCabecera = 260.0;

  Rutina get _rutina {
    final rutinas = context.watch<RutinasProvider>().rutinas;
    return rutinas.firstWhere(
      (r) => r.id == widget.rutina.id,
      orElse: () => widget.rutina,
    );
  }

  Future<void> _reordenar(int desde, int hasta) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await context.read<RutinasProvider>().reordenar(
        widget.rutina.id,
        desde,
        hasta,
      );
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el nuevo orden.')),
      );
    }
  }

  void _empezar() {
    context.read<NavegacionProvider>().irA(Pestana.entrenamiento);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rutina = _rutina;
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final ejercicios = rutina.ejercicios;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _altoCabecera,
            backgroundColor: tema.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: const _BotonAtras(),
            flexibleSpace: _Cabecera(rutina: rutina),
          ),
          if (rutina.grupos.isNotEmpty)
            SliverToBoxAdapter(
              child: Aparecer(
                indice: 1,
                child: _Grupos(
                  grupos: rutina.grupos,
                  seleccionado: _grupo,
                  onTap: (grupo) =>
                      setState(() => _grupo = _grupo == grupo ? null : grupo),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Aparecer(
              indice: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'EJERCICIOS',
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: colores.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (ejercicios.length > 1) ...[
                      Icon(
                        Icons.drag_indicator,
                        size: 14,
                        color: colores.onSurfaceVariant,
                      ),
                      Text(
                        'Arrastra para reordenar',
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (ejercicios.isEmpty)
            const SliverToBoxAdapter(child: _SinEjercicios())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: ejercicios.length,
                onReorderItem: _reordenar,
                proxyDecorator: _alArrastrar,
                itemBuilder: (context, i) {
                  final ejercicio = ejercicios[i];
                  return Padding(
                    key: ValueKey(ejercicio.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Aparecer(
                      indice: 3 + i,
                      child: EjercicioRutinaCard(
                        ejercicio: ejercicio,
                        indice: i,
                        expandido: _expandido == ejercicio.id,
                        atenuado: _grupo != null && ejercicio.grupo != _grupo,
                        onTap: () => setState(
                          () => _expandido = _expandido == ejercicio.id
                              ? null
                              : ejercicio.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: ejercicios.isEmpty
          ? null
          : Aparecer(
              indice: 4,
              desde: const Offset(0, 60),
              duracion: const Duration(milliseconds: 600),
              child: _BotonEmpezar(onPressed: _empezar),
            ),
    );
  }

  /// La tarjeta que se arrastra se levanta: crece un poco y proyecta sombra.
  Widget _alArrastrar(Widget hijo, int indice, Animation<double> animacion) {
    final colores = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animacion.value);
        return Transform.scale(
          scale: lerpDouble(1, 1.04, t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              boxShadow: [
                BoxShadow(
                  color: colores.primary.withValues(alpha: 0.35 * t),
                  blurRadius: 24 * t,
                  offset: Offset(0, 8 * t),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(type: MaterialType.transparency, child: hijo),
    );
  }
}

/// Portada con el nombre encima. Al hacer scroll se encoge: la información se
/// desvanece hacia abajo y el nombre aparece en la barra.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final arriba = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, restricciones) {
        // 1 = desplegada, 0 = colapsada en la barra.
        final minimo = kToolbarHeight + arriba;
        final despliegue =
            ((restricciones.maxHeight - minimo) /
                    (_RutinaDetallePageState._altoCabecera - minimo))
                .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Hero(
                tag: heroFotoRutina(rutina.id),
                child: FotoRutina(categoria: rutina.categoria, tamanoIcono: 40),
              ),
            ),
            // Degradado para que el texto se lea sobre la portada.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1],
                  colors: [
                    tema.scaffoldBackgroundColor.withValues(alpha: 0),
                    tema.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Opacity(
                opacity: Curves.easeIn.transform(despliegue),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - despliegue)),
                  child: _Titulo(rutina: rutina),
                ),
              ),
            ),
            Positioned(
              top: arriba,
              left: 56,
              right: 16,
              height: kToolbarHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: Curves.easeIn.transform(
                    (1 - despliegue * 2.5).clamp(0.0, 1.0),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rutina.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colores.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Aparecer(
      desde: const Offset(-24, 0),
      duracion: const Duration(milliseconds: 550),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            [
              'Rutina',
              if (rutina.categoria.isNotEmpty) rutina.categoria,
            ].join(' · ').toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: colores.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rutina.nombre,
            style: tema.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rutina.resumen,
            style: tema.textTheme.bodySmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Atrás sobre un círculo, para que se vea encima de la portada.
class _BotonAtras extends StatelessWidget {
  const _BotonAtras();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: colores.surface.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: const BackButton(),
      ),
    );
  }
}

/// Chips de los grupos musculares. Tocar uno resalta sus ejercicios.
class _Grupos extends StatelessWidget {
  const _Grupos({
    required this.grupos,
    required this.seleccionado,
    required this.onTap,
  });

  final List<String> grupos;
  final String? seleccionado;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: grupos.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final grupo = grupos[i];
          final activo = grupo == seleccionado;
          return PressableScale(
            pressedScale: 0.92,
            child: GestureDetector(
              onTap: () => onTap(grupo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: activo ? 16 : 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo
                      ? colores.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activo ? colores.primary : colores.outlineVariant,
                    width: activo ? 1.5 : 1,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: (tema.textTheme.labelMedium ?? const TextStyle())
                      .copyWith(
                        color: activo
                            ? colores.primary
                            : colores.onSurfaceVariant,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      ),
                  child: Text(grupo),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BotonEmpezar extends StatelessWidget {
  const _BotonEmpezar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colores.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: PressableScale(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Empezar rutina'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SinEjercicios extends StatelessWidget {
  const _SinEjercicios();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Text(
        'Esta rutina aún no tiene ejercicios.',
        textAlign: TextAlign.center,
        style: tema.textTheme.bodyMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
