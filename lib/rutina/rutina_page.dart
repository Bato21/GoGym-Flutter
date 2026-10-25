import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rutina.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/navegacion_provider.dart';
import '../providers/rutinas_provider.dart';
import '../widgets/aparecer.dart';
import 'rutina_detalle_page.dart';
import 'widgets/rutina_card.dart';

/// Rutinas de la cuenta. La que toca según la rotación va destacada; tocar una
/// abre su detalle.
class RutinaPage extends StatefulWidget {
  const RutinaPage({super.key});

  @override
  State<RutinaPage> createState() => _RutinaPageState();
}

class _RutinaPageState extends State<RutinaPage> {
  /// Sube cada vez que se entra a la pestaña: cambia las keys de las tarjetas y
  /// así la entrada en cascada se repite (IndexedStack la construye oculta).
  int _visita = 0;
  Pestana? _pestanaAnterior;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final actual = context.watch<NavegacionProvider>().actual;
    if (actual == Pestana.rutina && _pestanaAnterior != Pestana.rutina) {
      _visita++;
    }
    _pestanaAnterior = actual;
  }

  Future<void> _recargar() async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await context.read<RutinasProvider>().recargar();
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar. Revisa tu conexión.'),
        ),
      );
    }
  }

  void _abrir(Rutina rutina) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            RutinaDetallePage(rutina: rutina),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rutinas = context.watch<RutinasProvider>();
    final historial = context.watch<EntrenamientosProvider>().historial;
    final lista = rutinas.rutinas;
    final siguiente = rutinas.siguiente(historial);
    // Posición de cada rutina en la rotación (solo las que se pueden empezar).
    final orden = {
      for (final (i, r) in rutinas.disponibles.indexed) r.id: i + 1,
    };

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Aparecer(
                key: ValueKey('encabezado-$_visita'),
                desde: const Offset(-24, 0),
                child: _Encabezado(
                  resumen: lista.isEmpty
                      ? 'Tu plan de entrenamiento'
                      : '${lista.length} '
                            '${lista.length == 1 ? 'rutina' : 'rutinas'} · '
                            'rotan en orden',
                ),
              ),
              const SizedBox(height: 16),
              if (lista.isEmpty)
                const _SinRutinas()
              else
                for (final (i, rutina) in lista.indexed)
                  Aparecer(
                    key: ValueKey('rutina-${rutina.id}-$_visita'),
                    indice: i + 1,
                    desde: const Offset(0, 36),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RutinaCard(
                        rutina: rutina,
                        orden: orden[rutina.id],
                        siguiente: rutina.id == siguiente?.id,
                        onTap: () => _abrir(rutina),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen chico arriba y el título grande, igual que el saludo de Inicio.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.resumen});

  final String resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resumen,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Rutinas',
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SinRutinas extends StatelessWidget {
  const _SinRutinas();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 32),
      child: Aparecer(
        desde: const Offset(0, 16),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, escala, child) =>
                  Transform.scale(scale: escala, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colores.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 32,
                  color: colores.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes rutinas',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando armes una, aparecerá aquí con sus ejercicios.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
