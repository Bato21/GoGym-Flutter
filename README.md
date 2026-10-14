# GoGym-Flutter

Versión en Flutter de Go Gym (la versión original está en Ionic, en `Go-Gym/GG`).

## Requisitos

- Flutter (estable) — incluye Dart. Verificar con `flutter doctor`.

## Configurar Supabase

La app usa el mismo proyecto Supabase que la versión Ionic (tablas `perfiles`,
`rutinas`, `sesiones`; ver `supabase/migrations` en `Bato21/Go-Gym`).

1. Copia `env.example.json` a `env.json` (está en `.gitignore`).
2. Completa `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` (Supabase → Project Settings → API).
   Nunca uses la secret key ni la `service_role`.

## Correr el proyecto

```bash
flutter pub get
flutter run --dart-define-from-file=env.json            # elige dispositivo
flutter run -d chrome --dart-define-from-file=env.json  # directo en el navegador
flutter test
```

En VS Code, la configuración "Go Gym" de `.vscode/launch.json` ya pasa `env.json`.
En Windows, compilar para escritorio requiere activar el Modo de desarrollador.

## Estructura

Replica la estructura de la app de Ionic (`src/app/...`):

```
lib/
├── main.dart                     # Punto de entrada (equivale a app.component)
├── config/env.dart               # URL y key de Supabase (desde env.json)
├── theme/app_theme.dart          # Colores y tema claro/oscuro (variables.scss)
├── auth/auth_gate.dart           # Login o pestañas según la sesión
├── login/login_page.dart         # Iniciar sesión / crear cuenta
├── data/datos_repositorio.dart   # Lecturas a Supabase
├── models/                       # Perfil, Rutina, Sesion
├── providers/                    # Estado compartido (Provider)
├── utils/                        # Fechas y formato de números
├── tabs/tabs_page.dart           # Barra de pestañas inferior (tabs.page)
├── widgets/                      # Widgets compartidos (StatCard, SesionCard…)
├── inicio/inicio_page.dart       # Dashboard (hecho)
├── entrenamiento/entrenamiento_page.dart
├── rutina/rutina_page.dart
├── calorias/calorias_page.dart
├── logros/logros_page.dart
└── perfil/perfil_page.dart
```

Las páginas sin hacer muestran un texto "en construcción" (`PaginaEnConstruccion`).
Para trabajar una vista, reemplaza el `body` de su `Scaffold` en el archivo de la página.
