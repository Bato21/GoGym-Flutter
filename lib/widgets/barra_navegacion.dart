import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Un destino de la barra inferior. [iconoActivo] es la versión rellena que se
/// muestra cuando la pestaña está seleccionada.
class DestinoBarra {
  const DestinoBarra({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
}

/// Barra de pestañas inferior. Para que siempre se sepa dónde se está, la
/// pestaña activa lleva el ícono relleno sobre una pastilla azul que se
/// desliza de una pestaña a otra, y su etiqueta en azul y negrita.
class BarraNavegacion extends StatelessWidget {
  const BarraNavegacion({
    super.key,
    required this.destinos,
    required this.indice,
    required this.onTap,
  });

  final List<DestinoBarra> destinos;
  final int indice;
  final ValueChanged<int> onTap;

  static const _alto = 64.0;
  static const _anchoPastilla = 52.0;
  static const _altoPastilla = 30.0;
  static const _duracion = Duration(milliseconds: 320);

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
        child: SizedBox(
          height: _alto,
          child: LayoutBuilder(
            builder: (context, restricciones) {
              final anchoItem = restricciones.maxWidth / destinos.length;
              return Stack(
                children: [
                  // Pastilla que viaja hasta la pestaña activa.
                  AnimatedPositioned(
                    duration: _duracion,
                    curve: Curves.easeOutBack,
                    top: 7,
                    left: anchoItem * indice + (anchoItem - _anchoPastilla) / 2,
                    width: _anchoPastilla,
                    height: _altoPastilla,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colores.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(_altoPastilla / 2),
                        border: Border.all(
                          color: colores.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, destino) in destinos.indexed)
                        Expanded(
                          child: _Item(
                            destino: destino,
                            activo: i == indice,
                            onTap: () {
                              if (i != indice) HapticFeedback.selectionClick();
                              onTap(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destino,
    required this.activo,
    required this.onTap,
  });

  final DestinoBarra destino;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final color = activo ? colores.primary : colores.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: activo,
      label: destino.etiqueta,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: _altoIcono,
              child: Center(
                // Al activarse, el ícono da un pequeño salto.
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(activo),
                  tween: Tween(begin: activo ? 0.7 : 1, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  builder: (context, escala, child) =>
                      Transform.scale(scale: escala, child: child),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      activo ? destino.iconoActivo : destino.icono,
                      key: ValueKey(activo),
                      size: 22,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: (tema.textTheme.labelSmall ?? const TextStyle()).copyWith(
                fontSize: 11,
                color: color,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                destino.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _altoIcono = 30.0;
}
