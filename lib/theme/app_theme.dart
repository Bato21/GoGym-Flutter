import 'package:flutter/material.dart';

/// Colores y temas de la app. Equivalente a `src/theme/variables.scss` en Ionic.
class AppTheme {
  AppTheme._();

  // Azul de marca del mockup.
  static const Color primario = Color(0xFF4C8DFF);

  // Fondos oscuros del mockup.
  static const Color fondoOscuro = Color(0xFF0B1220);
  static const Color tarjetaOscura = Color(0xFF121A2B);
  static const Color bordeOscuro = Color(0xFF223049);

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primario,
          primary: primario,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get oscuro {
    final esquema = ColorScheme.fromSeed(
      seedColor: primario,
      primary: primario,
      brightness: Brightness.dark,
    ).copyWith(
      surface: fondoOscuro,
      surfaceContainer: tarjetaOscura,
      outlineVariant: bordeOscuro,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondoOscuro,
      cardColor: tarjetaOscura,
      appBarTheme: const AppBarTheme(backgroundColor: fondoOscuro),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: fondoOscuro,
      ),
    );
  }
}
