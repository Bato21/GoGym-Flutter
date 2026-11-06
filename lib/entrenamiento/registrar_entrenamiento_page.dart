import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_repositorio.dart';
import '../models/ejercicio_catalogo.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import '../providers/entrenamientos_provider.dart';
import '../utils/validadores.dart';
import '../widgets/selector_ejercicio.dart';
import '../widgets/tarjeta.dart';

/// Abre el formulario. Sin argumentos registra un entrenamiento libre; con
/// [rutina] precarga sus ejercicios; con [existente] lo edita.
Future<void> abrirRegistro(
  BuildContext context, {
  Sesion? existente,
  Rutina? rutina,
  DateTime Function() ahora = DateTime.now,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => RegistrarEntrenamientoPage(
      existente: existente,
      rutina: rutina,
      ahora: ahora,
    ),
  ),
);

/// Pide confirmación antes de borrar un entrenamiento. true = borrar.
Future<bool> confirmarBorrado(BuildContext context) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Borrar entrenamiento'),
      content: const Text(
        'Se borrará de tu historial y dejará de contar para la racha y los '
        'logros. No se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-borrar'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

/// Registrar entrenamiento (vista 02 del mockup). El mismo formulario sirve
/// para crear y para editar: si recibe [existente], parte con sus datos y al
/// guardar lo reemplaza. Toda escritura pasa por [EntrenamientosProvider].
class RegistrarEntrenamientoPage extends StatefulWidget {
  const RegistrarEntrenamientoPage({
    super.key,
    this.existente,
    this.rutina,
    this.ahora = DateTime.now,
  });

  final Sesion? existente;
  final Rutina? rutina;

  /// Reloj inyectable para las pruebas.
  final DateTime Function() ahora;

  @override
  State<RegistrarEntrenamientoPage> createState() =>
      _RegistrarEntrenamientoPageState();
}

class _RegistrarEntrenamientoPageState
    extends State<RegistrarEntrenamientoPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _minutos;
  late final List<_Borrador> _ejercicios;

  /// Ids para los ejercicios nuevos; parten del reloj, como en Ionic.
  late int _siguienteId;

  /// El catálogo se pide la primera vez que se abre el selector.
  Future<List<EjercicioCatalogo>>? _catalogo;
  bool _guardando = false;

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final existente = widget.existente;
    final rutina = widget.rutina;
    _siguienteId = widget.ahora().millisecondsSinceEpoch;

    _nombre = TextEditingController(
      text: existente?.nombre ?? rutina?.nombre ?? '',
    );
    final minutos = existente?.duracion.inMinutes ?? rutina?.minutos ?? 0;
    _minutos = TextEditingController(text: minutos > 0 ? '$minutos' : '');

    if (existente != null) {
      _ejercicios = [for (final e in existente.ejercicios) _Borrador.desde(e)];
    } else if (rutina != null) {
      _ejercicios = [
        for (final e in rutina.ejercicios)
          _Borrador.desdeRutina(e, ++_siguienteId),
      ];
    } else {
      _ejercicios = [_Borrador(id: ++_siguienteId)];
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _minutos.dispose();
    for (final e in _ejercicios) {
      e.dispose();
    }
    super.dispose();
  }

  void _agregarEjercicio() =>
      setState(() => _ejercicios.add(_Borrador(id: ++_siguienteId)));

  void _quitarEjercicio(_Borrador borrador) {
    setState(() => _ejercicios.remove(borrador));
    borrador.dispose();
  }

  Future<void> _elegirEjercicio(_Borrador borrador) async {
    _catalogo ??= context.read<DatosRepositorio>().catalogoEjercicios();
    final elegido = await elegirEjercicio(context, _catalogo!);
    if (elegido != null) setState(() => borrador.elegir(elegido));
  }

  Future<void> _guardar() async {
    final mensajero = ScaffoldMessenger.of(context);
    if (_ejercicios.isEmpty) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ejercicio.')),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;

    final provider = context.read<EntrenamientosProvider>();
    final navegador = Navigator.of(context);
    final existente = widget.existente;
    final duracion = Duration(minutes: int.parse(_minutos.text.trim()));
    // Uno nuevo se registra al terminar: empezó hace [duracion].
    final inicio = existente?.inicio ?? widget.ahora().subtract(duracion);
    final sesion = Sesion(
      id: existente?.id ?? widget.ahora().millisecondsSinceEpoch,
      nombre: _nombre.text.trim(),
      rutinaId: existente?.rutinaId ?? widget.rutina?.id,
      inicio: inicio,
      fin: inicio.add(duracion),
      ejercicios: [for (final e in _ejercicios) e.aEjercicio()],
    );

    setState(() => _guardando = true);
    try {
      if (existente == null) {
        await provider.agregar(sesion);
      } else {
        await provider.editar(sesion);
      }
      navegador.pop();
      mensajero.showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Entrenamiento actualizado' : 'Entrenamiento guardado',
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _guardando = false);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Revisa tu conexión.'),
        ),
      );
    }
  }

  Future<void> _borrar() async {
    final existente = widget.existente;
    if (existente == null || !await confirmarBorrado(context)) return;
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      await context.read<EntrenamientosProvider>().borrar(existente.id);
      navegador.pop();
      mensajero.showSnackBar(
        const SnackBar(content: Text('Entrenamiento borrado')),
      );
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo borrar. Revisa tu conexión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar entrenamiento' : 'Registrar entrenamiento',
        ),
        actions: [
          if (_editando)
            IconButton(
              key: const Key('borrar-sesion'),
              tooltip: 'Borrar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _guardando ? null : _borrar,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: const Key('campo-nombre'),
                    controller: _nombre,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Push A, Piernas…',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Ponle un nombre' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const Key('campo-minutos'),
                    controller: _minutos,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duración',
                      suffixText: 'min',
                    ),
                    validator: validarMinutos,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'EJERCICIOS',
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, borrador) in _ejercicios.indexed)
              Padding(
                key: ValueKey(borrador.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: _FilaEjercicio(
                  indice: i,
                  borrador: borrador,
                  onElegir: () => _elegirEjercicio(borrador),
                  onQuitar: () => _quitarEjercicio(borrador),
                ),
              ),
            OutlinedButton.icon(
              key: const Key('agregar-ejercicio'),
              onPressed: _agregarEjercicio,
              icon: const Icon(Icons.add),
              label: const Text('Agregar ejercicio'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              key: const Key('guardar-entrenamiento'),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      _editando ? 'Guardar cambios' : 'Guardar entrenamiento',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 45.0 → "45", 22.5 → "22.5".
String _textoKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toString();

/// Un ejercicio mientras se edita: el ejercicio elegido del catálogo y los
/// controladores de peso, repeticiones y series.
class _Borrador {
  _Borrador({
    required this.id,
    this.catalogoId = '',
    String nombre = '',
    this.grupo = '',
    this.imagen,
    this.met,
    this.repsObjetivo,
    String kg = '',
    String reps = '',
    String series = '',
    this.originales,
  }) : ejercicio = TextEditingController(text: nombre),
       kg = TextEditingController(text: kg),
       reps = TextEditingController(text: reps),
       series = TextEditingController(text: series),
       _inicial = (kg, reps, series);

  /// Ejercicio ya guardado. El formulario usa un solo peso y repeticiones por
  /// ejercicio, tomados de la primera serie.
  factory _Borrador.desde(EjercicioSesion e) {
    final primera = e.series.isEmpty ? null : e.series.first;
    return _Borrador(
      id: e.id,
      catalogoId: e.catalogoId,
      nombre: e.nombre,
      grupo: e.grupo,
      imagen: e.imagen,
      met: e.met,
      repsObjetivo: e.repsObjetivo,
      kg: _textoKg(primera?.kg ?? 0),
      reps: primera?.reps == null ? '' : '${primera!.reps}',
      series: e.series.isEmpty ? '' : '${e.series.length}',
      originales: e.series,
    );
  }

  /// Ejercicio planificado: precarga el peso, las repeticiones objetivo y
  /// las series de la rutina.
  factory _Borrador.desdeRutina(Ejercicio e, int id) => _Borrador(
    id: id,
    catalogoId: e.catalogoId ?? '',
    nombre: e.nombre,
    grupo: e.grupo,
    imagen: e.imagen,
    met: e.met,
    repsObjetivo: e.repeticiones > 0 ? e.repeticiones : null,
    kg: _textoKg(e.cargaKg),
    reps: e.repeticiones > 0 ? '${e.repeticiones}' : '',
    series: e.series > 0 ? '${e.series}' : '',
  );

  final int id;
  String catalogoId;
  String grupo;
  String? imagen;
  double? met;
  final int? repsObjetivo;
  final TextEditingController ejercicio;
  final TextEditingController kg;
  final TextEditingController reps;
  final TextEditingController series;

  /// Las series tal como estaban guardadas, para no perder el detalle serie a
  /// serie (p. ej. 80 kg × 5 y luego 60 kg × 10) si no se tocan los campos.
  final List<Serie>? originales;
  final (String, String, String) _inicial;

  void elegir(EjercicioCatalogo c) {
    catalogoId = c.id;
    ejercicio.text = c.nombre;
    grupo = c.grupo;
    imagen = c.imagen;
    met = c.met;
  }

  /// Llamar solo con el formulario validado.
  EjercicioSesion aEjercicio() {
    final sinCambios = (kg.text, reps.text, series.text) == _inicial;
    final peso = leerDecimal(kg.text)!;
    final repeticiones = int.parse(reps.text.trim());
    return EjercicioSesion(
      id: id,
      catalogoId: catalogoId,
      nombre: ejercicio.text,
      grupo: grupo,
      imagen: imagen,
      met: met,
      repsObjetivo: repsObjetivo,
      series: sinCambios && originales != null
          ? originales!
          : List.generate(
              int.parse(series.text.trim()),
              (_) => Serie(kg: peso, reps: repeticiones),
            ),
    );
  }

  void dispose() {
    ejercicio.dispose();
    kg.dispose();
    reps.dispose();
    series.dispose();
  }
}

class _FilaEjercicio extends StatelessWidget {
  const _FilaEjercicio({
    required this.indice,
    required this.borrador,
    required this.onElegir,
    required this.onQuitar,
  });

  final int indice;
  final _Borrador borrador;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final objetivo = borrador.repsObjetivo;
    return Tarjeta(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('campo-ejercicio-$indice'),
                  controller: borrador.ejercicio,
                  readOnly: true,
                  onTap: onElegir,
                  decoration: InputDecoration(
                    labelText: 'Ejercicio',
                    hintText: 'Elegir del catálogo',
                    helperText: borrador.grupo.isEmpty ? null : borrador.grupo,
                    suffixIcon: const Icon(Icons.expand_more),
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Elige un ejercicio' : null,
                ),
              ),
              IconButton(
                key: Key('quitar-ejercicio-$indice'),
                tooltip: 'Quitar',
                onPressed: onQuitar,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('campo-peso-$indice'),
                  controller: borrador.kg,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    suffixText: 'kg',
                    helperText: '0 = corporal',
                  ),
                  validator: validarPeso,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: Key('campo-reps-$indice'),
                  controller: borrador.reps,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Reps',
                    helperText: objetivo == null ? null : 'Objetivo $objetivo',
                  ),
                  validator: validarEnteroPositivo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: Key('campo-series-$indice'),
                  controller: borrador.series,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Series'),
                  validator: validarEnteroPositivo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
