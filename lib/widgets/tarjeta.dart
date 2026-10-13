import 'package:flutter/material.dart';

/// Contenedor redondeado con borde fino, como las tarjetas del mockup.
/// [destacada] la pinta con el azul de marca (p. ej. "Toca hoy").
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.destacada = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool destacada;
  final VoidCallback? onTap;

  static const radio = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Material(
      color: destacada
          ? colores.primary.withValues(alpha: 0.08)
          : colores.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: radio,
        side: BorderSide(
          color: destacada ? colores.primary : colores.outlineVariant,
          width: destacada ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
