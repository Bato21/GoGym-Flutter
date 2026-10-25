import 'package:flutter/material.dart';

/// Pide confirmación antes de cerrar la cuenta y muestra un mensaje si falla.
Future<void> confirmarCierreSesion(
  BuildContext context,
  Future<void> Function() cerrarSesion,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.logout_rounded),
      title: const Text('Cerrar sesión'),
      content: const Text(
        '¿Quieres salir de tu cuenta? Tendrás que iniciar sesión nuevamente.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-cerrar-sesion'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;

  try {
    await cerrarSesion();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No se pudo cerrar la sesión. Intenta nuevamente.'),
        ),
      );
  }
}
