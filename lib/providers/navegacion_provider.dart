import 'package:flutter/foundation.dart';

/// Pestañas de la barra inferior, en el orden en que aparecen.
enum Pestana { inicio, entrenamiento, rutina, calorias, logros, perfil }

/// Pestaña activa. Permite que una vista abra otra (p. ej. "Empezar" en
/// Inicio lleva a Entrenamiento).
class NavegacionProvider extends ChangeNotifier {
  Pestana _actual = Pestana.inicio;

  Pestana get actual => _actual;

  void irA(Pestana pestana) {
    if (pestana == _actual) return;
    _actual = pestana;
    notifyListeners();
  }
}
