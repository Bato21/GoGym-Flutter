import 'package:flutter/material.dart';

/// Entrada en cascada: el hijo aparece desvaneciéndose y deslizándose hasta su
/// lugar. [indice] retrasa la entrada para que una lista llegue de a uno.
/// Con las animaciones del sistema desactivadas, aparece de inmediato.
class Aparecer extends StatefulWidget {
  const Aparecer({
    super.key,
    required this.child,
    this.indice = 0,
    this.desde = const Offset(0, 24),
    this.duracion = const Duration(milliseconds: 450),
    this.paso = const Duration(milliseconds: 60),
  });

  final Widget child;
  final int indice;

  /// Desplazamiento inicial en píxeles.
  final Offset desde;
  final Duration duracion;

  /// Retraso entre un índice y el siguiente.
  final Duration paso;

  /// Pasado este índice ya no se suma retraso: una lista larga no tarda más.
  static const indiceMaximo = 10;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _avance;
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    final retraso = widget.paso * widget.indice.clamp(0, Aparecer.indiceMaximo);
    final total = retraso + widget.duracion;
    _controlador = AnimationController(vsync: this, duration: total);
    _avance = CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        retraso.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controlador.value = 1;
    } else {
      _controlador.forward();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _avance,
      child: AnimatedBuilder(
        animation: _avance,
        builder: (context, child) => Transform.translate(
          offset: widget.desde * (1 - _avance.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
