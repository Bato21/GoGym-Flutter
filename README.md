# GoGym-Flutter

Versión en Flutter de Go Gym (la versión original está en Ionic, en `Go-Gym/GG`).

## Requisitos

- Flutter (estable) — incluye Dart. Verificar con `flutter doctor`.

## Configurar Supabase

La app usa el mismo proyecto Supabase que la versión Ionic (tablas `perfiles`,
`rutinas`, `sesiones`, `registros_calorias` y `ejercicios`; ver
`supabase/migrations` aquí y en `Bato21/Go-Gym`). Todas tienen RLS: cada cuenta
solo lee y escribe sus propias filas (`auth.uid() = user_id`); el catálogo
`ejercicios` es de solo lectura.

1. Copia `env.example.json` a `env.json` (está en `.gitignore`).
2. Completa `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` (Supabase → Project Settings → API).
   Nunca uses la secret key ni la `service_role`.

El plan gratuito pausa el proyecto tras una semana sin uso: revisa que esté
activo antes de una presentación.

## Correr el proyecto

```bash
flutter pub get
flutter run --dart-define-from-file=env.json            # elige dispositivo
flutter run -d chrome --dart-define-from-file=env.json  # directo en el navegador
flutter analyze
flutter test
```

En VS Code, la configuración "Go Gym" de `.vscode/launch.json` ya pasa `env.json`.
En Windows, compilar para escritorio requiere activar el Modo de desarrollador.

## Funcionalidades

| Pestaña | Qué hace |
|---|---|
| Inicio | Racha, totales de la semana, la rutina que toca y las últimas sesiones. «Empezar» abre el registro con la rutina cargada. |
| Entrenar | **Historial** (tocar para editar, deslizar para borrar), **Biblioteca** (catálogo de Supabase con búsqueda y filtros) y **wger** (ejercicios desde la API REST de wger). El botón «Registrar» abre el formulario. |
| Rutinas | Rutinas con su detalle, reordenar ejercicios y «Empezar rutina». |
| Calorías | Anillo con lo que queda para la meta, macros, comidas y actividad del día. Los entrenamientos suman a la quema solos (estimación MET × peso × tiempo). |
| Logros | Desbloqueos y avances calculados desde el historial. |
| Perfil | Datos del usuario, agenda, editar perfil y cerrar sesión. |

### Requisitos de la Unidad 2

| Requisito | Dónde |
|---|---|
| 1. Login con Supabase | `login/login_page.dart`, `auth/auth_gate.dart`; cerrar sesión en Perfil e Inicio. |
| 2. Datos de la API | `data/wger_api.dart` (GET a `wger.de/api/v2/exerciseinfo/` con `http`) mostrado con `FutureBuilder` en `biblioteca/wger_page.dart` (carga, error con reintento, datos). |
| 3. Navegación | `WgerDetallePage`, `EjercicioDetallePage` y `RutinaDetallePage` reciben su objeto por constructor. |
| 4. Animaciones | Hero lista → detalle; `AnimatedContainer` en `widgets/chip_filtro.dart`; anillo y barras animadas en Calorías. |
| 5. Tabla en Supabase | `sesiones` y `registros_calorias` con RLS: crear, leer, editar y borrar en `data/datos_repositorio.dart`. |
| 6. Formulario con validación | `entrenamiento/registrar_entrenamiento_page.dart` (crear y editar con el mismo formulario); validadores en `utils/validadores.dart`. |
| 7. Estado con Provider | `EntrenamientosProvider` (compartido entre Inicio, Entrenar, Calorías, Logros y Perfil) y `CaloriasProvider`. |
| 8. Widgets propios | `SesionCard`, `EjercicioCard`, `StatCard` y más en `lib/widgets/`. |
| 9. GitHub | Una rama por funcionalidad y commits de los tres integrantes. |

## Estructura

Replica la estructura de la app de Ionic (`src/app/...`):

```
lib/
├── main.dart                     # Punto de entrada y providers (equivale a app.component)
├── config/env.dart               # URL y key de Supabase (desde env.json)
├── theme/app_theme.dart          # Colores y tema claro/oscuro (variables.scss)
├── auth/auth_gate.dart           # Login o pestañas según la sesión
├── login/login_page.dart         # Iniciar sesión / crear cuenta
├── data/
│   ├── datos_repositorio.dart    # Lecturas y escrituras a Supabase
│   └── wger_api.dart             # Cliente de la API REST de wger
├── models/                       # Perfil, Rutina, Sesion, RegistroCalorias, EjercicioWger…
├── providers/                    # Estado compartido (Provider)
├── utils/                        # Fechas, formato de números y validadores
├── tabs/tabs_page.dart           # Barra de pestañas inferior (tabs.page)
├── widgets/                      # Widgets compartidos (StatCard, SesionCard, ChipFiltro…)
├── inicio/inicio_page.dart       # Dashboard
├── entrenamiento/
│   ├── entrenamiento_page.dart   # Historial, Biblioteca y wger
│   └── registrar_entrenamiento_page.dart
├── biblioteca/                   # Catálogo de Supabase y vista de wger, con sus detalles
├── rutina/                       # Rutinas y su detalle
├── calorias/calorias_page.dart
├── logros/logros_page.dart
└── perfil/perfil_page.dart
```

## Pruebas

`flutter test` usa un repositorio en memoria (`test/repositorio_falso.dart`) y un
cliente HTTP falso para wger (`test/wger_falso.dart`): no necesita internet ni
Supabase.

### Prueba manual con dos cuentas

Antes de presentar, comprobar que RLS aísla los datos:

1. Crear la cuenta A, registrar un entrenamiento y una comida.
2. Cerrar sesión, crear la cuenta B: su historial y sus calorías deben estar vacíos.
3. En B, registrar, editar y borrar un entrenamiento.
4. Volver a A: sus datos siguen intactos y no aparece nada de B.
