import 'package:flutter/material.dart';

/// true si el sistema pide reducir animaciones.
bool sinAnimaciones(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Controlador que arranca solo una vez montado, tras [retraso], y que se
/// completa de inmediato si el sistema pide reducir animaciones. El retraso va
/// dentro de la propia animación (con un Interval), sin Timers.
mixin AnimacionDeEntrada<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController controlador;
  late final Animation<double> avance;
  bool _iniciado = false;

  Duration get retraso;
  Duration get duracion;
  Curve get curva;

  @override
  void initState() {
    super.initState();
    final total = retraso + duracion;
    controlador = AnimationController(vsync: this, duration: total);
    avance = CurvedAnimation(
      parent: controlador,
      curve: Interval(
        retraso.inMicroseconds / total.inMicroseconds,
        1,
        curve: curva,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (sinAnimaciones(context)) {
      controlador.value = 1;
    } else {
      controlador.forward();
    }
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }
}

/// Aparece creciendo desde [desde] con un pequeño rebote.
class Rebote extends StatefulWidget {
  const Rebote({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
    this.duracion = const Duration(milliseconds: 550),
    this.desde = 0.4,
  });

  final Widget child;
  final Duration retraso;
  final Duration duracion;
  final double desde;

  @override
  State<Rebote> createState() => _ReboteState();
}

class _ReboteState extends State<Rebote>
    with SingleTickerProviderStateMixin, AnimacionDeEntrada {
  @override
  Duration get retraso => widget.retraso;
  @override
  Duration get duracion => widget.duracion;
  @override
  Curve get curva => Curves.easeOutBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: avance,
      builder: (context, child) => Opacity(
        opacity: avance.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: widget.desde + (1 - widget.desde) * avance.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Avance de 0 a 1 que empieza tras [retraso]; el hijo se dibuja con él.
/// Sirve para rellenos, trazos y cualquier cosa que no sea solo entrar.
class Progreso extends StatefulWidget {
  const Progreso({
    super.key,
    required this.builder,
    this.retraso = Duration.zero,
    this.duracion = const Duration(milliseconds: 600),
    this.curva = Curves.easeOutCubic,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration retraso;
  final Duration duracion;
  final Curve curva;

  @override
  State<Progreso> createState() => _ProgresoState();
}

class _ProgresoState extends State<Progreso>
    with SingleTickerProviderStateMixin, AnimacionDeEntrada {
  @override
  Duration get retraso => widget.retraso;
  @override
  Duration get duracion => widget.duracion;
  @override
  Curve get curva => widget.curva;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: avance,
    builder: (context, _) => widget.builder(context, avance.value),
  );
}

/// Un destello que cruza el hijo una vez, en diagonal, tras [retraso].
class Destello extends StatelessWidget {
  const Destello({
    super.key,
    required this.child,
    this.retraso = const Duration(milliseconds: 700),
    this.radio = BorderRadius.zero,
  });

  final Widget child;
  final Duration retraso;
  final BorderRadius radio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: radio,
              child: Progreso(
                retraso: retraso,
                duracion: const Duration(milliseconds: 1100),
                curva: Curves.easeInOutCubic,
                builder: (context, t) => t == 0 || t == 1
                    ? const SizedBox.shrink()
                    : FractionalTranslation(
                        // De fuera por la izquierda a fuera por la derecha.
                        translation: Offset(-1 + 2 * t, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: const Alignment(-1, -0.4),
                              end: const Alignment(1, 0.4),
                              colors: [
                                color.withValues(alpha: 0),
                                color.withValues(alpha: 0.22),
                                color.withValues(alpha: 0),
                              ],
                              stops: const [0.3, 0.5, 0.7],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Número que cuenta desde 0 (o desde el valor anterior) hasta [valor].
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado({
    super.key,
    required this.valor,
    required this.builder,
    this.duracion = const Duration(milliseconds: 1100),
  });

  final double valor;
  final Widget Function(BuildContext context, double valor) builder;
  final Duration duracion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: sinAnimaciones(context) ? Duration.zero : duracion,
      curve: Curves.easeOutExpo,
      builder: (context, actual, _) => builder(context, actual),
    );
  }
}
