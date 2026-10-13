# GoGym-Flutter

Versión en Flutter de Go Gym (la versión original está en Ionic, en `Go-Gym/GG`).

## Requisitos

- Flutter (estable) — incluye Dart. Verificar con `flutter doctor`.

## Correr el proyecto

```bash
flutter pub get
flutter run            # elige dispositivo (Chrome, Windows, Android…)
flutter run -d chrome  # directo en el navegador
```

## Estructura

Replica la estructura de la app de Ionic (`src/app/...`):

```
lib/
├── main.dart                     # Punto de entrada (equivale a app.component)
├── theme/app_theme.dart          # Colores y tema claro/oscuro (variables.scss)
├── tabs/tabs_page.dart           # Barra de pestañas inferior (tabs.page)
├── widgets/                      # Widgets compartidos
├── inicio/inicio_page.dart
├── entrenamiento/entrenamiento_page.dart
├── rutina/rutina_page.dart
├── calorias/calorias_page.dart
├── logros/logros_page.dart
└── perfil/perfil_page.dart
```

Cada página por ahora muestra un texto "en construcción" (`PaginaEnConstruccion`).
Para trabajar una vista, reemplaza el `body` de su `Scaffold` en el archivo de la página.
