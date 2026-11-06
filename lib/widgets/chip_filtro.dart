import 'package:flutter/material.dart';

/// Chip de filtro que anima color y borde al seleccionarse (AnimatedContainer).
/// Lo usan la biblioteca y la vista de wger.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({
    super.key,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: seleccionado ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: seleccionado ? colores.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colores.primary),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? colores.onPrimary : colores.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
