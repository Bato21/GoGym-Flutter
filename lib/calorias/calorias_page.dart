import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/datos_repositorio.dart';
import '../models/ejercicio_catalogo.dart';
import '../models/perfil.dart';
import '../models/registro_calorias.dart';
import '../models/sesion.dart';
import '../providers/calorias_provider.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/perfil_provider.dart';
import '../utils/fechas.dart';
import '../utils/formato.dart';
import '../utils/validadores.dart';
import '../widgets/selector_ejercicio.dart';
import '../widgets/stat_card.dart';
import '../widgets/tarjeta.dart';

/// Calorías (vista 04 del mockup): anillo con lo que queda para la meta,
/// macros, comidas y actividad del día. Los entrenamientos registrados suman
/// a la quema solos; también se pueden anotar comidas y actividades sueltas.
/// La quema es una estimación (MET × peso × horas), no un dato exacto.
class CaloriasPage extends StatefulWidget {
  const CaloriasPage({super.key, this.ahora = DateTime.now});

  /// Reloj inyectable para las pruebas.
  final DateTime Function() ahora;

  @override
  State<CaloriasPage> createState() => _CaloriasPageState();
}

class _CaloriasPageState extends State<CaloriasPage> {
  late DateTime _dia;

  /// Carga del día que se mira, si no estaba en memoria. null = nada pendiente.
  Future<void>? _carga;

  /// El catálogo se pide la primera vez que se agrega una actividad.
  Future<List<EjercicioCatalogo>>? _catalogo;

  @override
  void initState() {
    super.initState();
    _dia = soloDia(widget.ahora());
    _carga = _cargaSiFalta();
  }

  bool get _esHoy => _dia == soloDia(widget.ahora());

  void _cambiarDia(int dias) => setState(() {
    _dia = sumarDias(_dia, dias);
    _carga = _cargaSiFalta();
  });

  /// Pide el día a Supabase si todavía no está en memoria.
  Future<void>? _cargaSiFalta() {
    final calorias = context.read<CaloriasProvider>();
    return calorias.cargado(_dia) ? null : calorias.cargarDia(_dia);
  }

  /// "Hoy · 14 oct", "Ayer · 13 oct" o "Lunes · 12 oct".
  String get _tituloDia {
    final hoy = widget.ahora();
    final dias = diasEntre(_dia, hoy);
    final nombre = dias == 0
        ? 'Hoy'
        : dias == 1
        ? 'Ayer'
        : nombreDia(_dia);
    return '$nombre · ${DateFormat('d MMM', 'es').format(_dia)}';
  }

  /// Corre una escritura y avisa si falla (el provider ya deshizo el cambio).
  Future<void> _guardar(Future<void> Function() escritura) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await escritura();
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Revisa tu conexión.'),
        ),
      );
    }
  }

  Future<void> _agregarComida() async {
    final calorias = context.read<CaloriasProvider>();
    final comida = await showModalBottomSheet<Comida>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormularioComida(ahora: widget.ahora),
    );
    if (comida != null) {
      await _guardar(() => calorias.agregarComida(_dia, comida));
    }
  }

  Future<void> _agregarActividad() async {
    final calorias = context.read<CaloriasProvider>();
    _catalogo ??= context.read<DatosRepositorio>().catalogoEjercicios();
    final ejercicio = await elegirEjercicio(context, _catalogo!);
    if (ejercicio == null || !mounted) return;
    final minutos = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoMinutos(ejercicio: ejercicio),
    );
    if (minutos == null) return;
    final actividad = Actividad(
      id: widget.ahora().millisecondsSinceEpoch,
      nombre: ejercicio.nombre,
      met: ejercicio.met,
      minutos: minutos,
    );
    await _guardar(() => calorias.agregarActividad(_dia, actividad));
  }

  Future<void> _ajustar(Perfil perfil) async {
    final perfiles = context.read<PerfilProvider>();
    final mensajero = ScaffoldMessenger.of(context);
    final nuevo = await showModalBottomSheet<Perfil>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormularioAjustes(perfil: perfil),
    );
    if (nuevo == null) return;
    try {
      await perfiles.actualizar(nuevo);
      mensajero.showSnackBar(const SnackBar(content: Text('Metas guardadas')));
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Revisa tu conexión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>().perfil;
    final calorias = context.watch<CaloriasProvider>();
    final historial = context.watch<EntrenamientosProvider>().historial;
    final tema = Theme.of(context);

    final registro = calorias.registro(_dia);
    final pesoKg = perfil?.pesoKg ?? 70;
    final meta = perfil?.metaCalorias ?? 2200;
    final entrenamientos = [
      for (final s in historial)
        if (soloDia(s.inicio) == _dia) s,
    ];
    final quema =
        entrenamientos.fold(0.0, (suma, s) => suma + s.kcalEstimadas(pesoKg)) +
        registro.actividades.fold(0.0, (suma, a) => suma + a.kcal(pesoKg));
    final ingesta = registro.ingesta;
    // El ejercicio "devuelve" calorías a la meta del día.
    final restantes = meta - ingesta + quema;
    final progreso = meta <= 0
        ? 0.0
        : ((ingesta - quema) / meta).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorías'),
        actions: [
          IconButton(
            key: const Key('ajustes-calorias'),
            tooltip: 'Metas',
            icon: const Icon(Icons.tune),
            onPressed: perfil == null ? null : () => _ajustar(perfil),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('dia-anterior'),
                tooltip: 'Día anterior',
                onPressed: () => _cambiarDia(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _tituloDia,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const Key('dia-siguiente'),
                tooltip: 'Día siguiente',
                // No se registran días que aún no pasan.
                onPressed: _esHoy ? null : () => _cambiarDia(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          FutureBuilder<void>(
            future: _carga,
            builder: (context, snapshot) {
              if (_carga == null ||
                  snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError) {
                return const SizedBox(height: 4);
              }
              if (snapshot.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(
                    () => _carga = context.read<CaloriasProvider>().cargarDia(
                      _dia,
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('No se pudo cargar el día. Reintentar'),
                );
              }
              return const LinearProgressIndicator(minHeight: 4);
            },
          ),
          const SizedBox(height: 8),
          Tarjeta(
            child: Column(
              children: [
                _Anillo(progreso: progreso, restantes: restantes),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        valor: formatearMiles(meta),
                        unidad: 'kcal',
                        etiqueta: 'Meta',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        valor: formatearMiles(ingesta),
                        unidad: 'kcal',
                        etiqueta: 'Consumidas',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        valor: formatearMiles(quema),
                        unidad: 'kcal',
                        etiqueta: 'Quemadas',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Column(
              children: [
                _BarraMacro(
                  nombre: 'Proteína',
                  actual: registro.proteina,
                  meta: perfil?.metaProteina ?? 150,
                ),
                const SizedBox(height: 12),
                _BarraMacro(
                  nombre: 'Carbohidratos',
                  actual: registro.carbohidratos,
                  meta: perfil?.metaCarbohidratos ?? 260,
                ),
                const SizedBox(height: 12),
                _BarraMacro(
                  nombre: 'Grasas',
                  actual: registro.grasas,
                  meta: perfil?.metaGrasas ?? 70,
                ),
              ],
            ),
          ),
          const _Titulo('COMIDAS'),
          if (registro.comidas.isEmpty)
            const _Vacio('Aún no anotas comidas este día.')
          else
            for (final comida in registro.comidas)
              _FilaRegistro(
                key: ValueKey('comida-${comida.id}'),
                icono: Icons.restaurant,
                titulo: comida.nombre,
                detalle:
                    'P ${_gramos(comida.proteina)} · '
                    'C ${_gramos(comida.carbohidratos)} · '
                    'G ${_gramos(comida.grasas)}',
                kcal: '${formatearMiles(comida.kcal)} kcal',
                onBorrar: () =>
                    _guardar(() => calorias.borrarComida(_dia, comida.id)),
              ),
          OutlinedButton.icon(
            key: const Key('agregar-comida'),
            onPressed: _agregarComida,
            icon: const Icon(Icons.add),
            label: const Text('Agregar comida'),
          ),
          const _Titulo('ACTIVIDAD'),
          if (entrenamientos.isEmpty && registro.actividades.isEmpty)
            const _Vacio('Sin actividad este día.'),
          for (final sesion in entrenamientos)
            _FilaRegistro(
              key: ValueKey('sesion-${sesion.id}'),
              icono: Icons.fitness_center,
              titulo: sesion.nombre,
              detalle: _detalleSesion(sesion),
              kcal: '${formatearMiles(sesion.kcalEstimadas(pesoKg))} kcal',
            ),
          for (final actividad in registro.actividades)
            _FilaRegistro(
              key: ValueKey('actividad-${actividad.id}'),
              icono: Icons.directions_run,
              titulo: actividad.nombre,
              detalle:
                  '${actividad.minutos} min · MET ${_decimal(actividad.met)}',
              kcal: '${formatearMiles(actividad.kcal(pesoKg))} kcal',
              onBorrar: () =>
                  _guardar(() => calorias.borrarActividad(_dia, actividad.id)),
            ),
          OutlinedButton.icon(
            key: const Key('agregar-actividad'),
            onPressed: _agregarActividad,
            icon: const Icon(Icons.add),
            label: const Text('Agregar actividad'),
          ),
          const SizedBox(height: 16),
          Text(
            'Las calorías quemadas son una estimación (MET × peso × tiempo) '
            'con tu peso de ${_decimal(pesoKg)} kg.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _detalleSesion(Sesion sesion) =>
      'Entrenamiento · ${formatearTiempo(sesion.duracion)}';
}

/// 24.0 → "24", 22.5 → "22,5".
String _decimal(double valor) => valor == valor.roundToDouble()
    ? valor.toInt().toString()
    : valor.toStringAsFixed(1).replaceAll('.', ',');

String _gramos(double valor) => '${_decimal(valor)} g';

/// Anillo de progreso: calorías netas sobre la meta. Se anima al cambiar.
class _Anillo extends StatelessWidget {
  const _Anillo({required this.progreso, required this.restantes});

  final double progreso;
  final double restantes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final pasado = restantes < 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progreso),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, valor, _) => SizedBox.square(
        dimension: 180,
        child: CustomPaint(
          painter: _PintorAnillo(
            progreso: valor,
            fondo: colores.outlineVariant,
            color: pasado ? colores.error : colores.primary,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatearMiles(restantes.abs()),
                  key: const Key('kcal-restantes'),
                  style: tema.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  pasado ? 'kcal sobre la meta' : 'kcal restantes',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo({
    required this.progreso,
    required this.fondo,
    required this.color,
  });

  final double progreso;
  final Color fondo;
  final Color color;

  static const _grosor = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = (size.shortestSide - _grosor) / 2;
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, radio, pincel..color = fondo);
    if (progreso <= 0) return;
    // Parte arriba (-90°) y avanza en el sentido del reloj.
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      2 * math.pi * progreso,
      false,
      pincel..color = color,
    );
  }

  @override
  bool shouldRepaint(_PintorAnillo anterior) =>
      anterior.progreso != progreso ||
      anterior.color != color ||
      anterior.fondo != fondo;
}

class _BarraMacro extends StatelessWidget {
  const _BarraMacro({
    required this.nombre,
    required this.actual,
    required this.meta,
  });

  final String nombre;
  final double actual;
  final int meta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fraccion = meta <= 0 ? 0.0 : (actual / meta).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(nombre, style: tema.textTheme.bodyMedium)),
            Text(
              '${_decimal(actual)} / $meta g',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(end: fraccion.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, valor, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: valor, minHeight: 8),
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        texto,
        style: tema.textTheme.labelMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        texto,
        style: tema.textTheme.bodyMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Una comida o actividad: ícono, título, detalle, kcal y (si se puede) borrar.
class _FilaRegistro extends StatelessWidget {
  const _FilaRegistro({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.kcal,
    this.onBorrar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final String kcal;
  final VoidCallback? onBorrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tarjeta(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(icono, size: 20, color: colores.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detalle,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: colores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(kcal, style: tema.textTheme.bodyMedium),
            if (onBorrar == null)
              const SizedBox(width: 12)
            else
              IconButton(
                tooltip: 'Borrar',
                onPressed: onBorrar,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formulario para anotar una comida. Devuelve la [Comida] al guardar.
class _FormularioComida extends StatefulWidget {
  const _FormularioComida({required this.ahora});

  final DateTime Function() ahora;

  @override
  State<_FormularioComida> createState() => _FormularioComidaState();
}

class _FormularioComidaState extends State<_FormularioComida> {
  final _form = GlobalKey<FormState>();
  final _kcal = TextEditingController();
  final _proteina = TextEditingController();
  final _carbohidratos = TextEditingController();
  final _grasas = TextEditingController();
  late String _tipo;

  @override
  void initState() {
    super.initState();
    // Sugiere el tipo según la hora.
    final hora = widget.ahora().hour;
    _tipo = hora < 11
        ? 'Desayuno'
        : hora < 16
        ? 'Almuerzo'
        : hora < 20
        ? 'Once'
        : hora < 23
        ? 'Cena'
        : 'Snack';
  }

  @override
  void dispose() {
    _kcal.dispose();
    _proteina.dispose();
    _carbohidratos.dispose();
    _grasas.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    double gramos(TextEditingController c) => leerDecimal(c.text) ?? 0;
    Navigator.of(context).pop(
      Comida(
        id: widget.ahora().millisecondsSinceEpoch,
        nombre: _tipo,
        kcal: int.parse(_kcal.text.trim()),
        proteina: gramos(_proteina),
        carbohidratos: gramos(_carbohidratos),
        grasas: gramos(_grasas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget campoGramos(
      String etiqueta,
      TextEditingController c,
      String clave,
    ) => Expanded(
      child: TextFormField(
        key: Key(clave),
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: etiqueta, suffixText: 'g'),
        validator: validarGramos,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar comida',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('campo-tipo-comida'),
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Comida'),
              items: [
                for (final tipo in tiposComida)
                  DropdownMenuItem(value: tipo, child: Text(tipo)),
              ],
              onChanged: (tipo) => setState(() => _tipo = tipo ?? _tipo),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('campo-kcal'),
              controller: _kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calorías',
                suffixText: 'kcal',
              ),
              validator: validarEnteroPositivo,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                campoGramos('Proteína', _proteina, 'campo-proteina'),
                const SizedBox(width: 10),
                campoGramos('Carbos', _carbohidratos, 'campo-carbohidratos'),
                const SizedBox(width: 10),
                campoGramos('Grasas', _grasas, 'campo-grasas'),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('guardar-comida'),
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pregunta cuántos minutos se hizo la actividad. Devuelve los minutos.
class _DialogoMinutos extends StatefulWidget {
  const _DialogoMinutos({required this.ejercicio});

  final EjercicioCatalogo ejercicio;

  @override
  State<_DialogoMinutos> createState() => _DialogoMinutosState();
}

class _DialogoMinutosState extends State<_DialogoMinutos> {
  final _form = GlobalKey<FormState>();
  final _minutos = TextEditingController(text: '30');

  @override
  void dispose() {
    _minutos.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(_minutos.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ejercicio.nombre),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('campo-minutos-actividad'),
          controller: _minutos,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '¿Cuántos minutos?',
            suffixText: 'min',
            helperText: 'MET ${_decimal(widget.ejercicio.met)}',
          ),
          validator: validarMinutos,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('aceptar-minutos'),
          onPressed: _aceptar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

/// Meta diaria, peso y metas de macros. Se guardan en el perfil, así valen
/// también en Inicio y Perfil. Devuelve el perfil actualizado.
class _FormularioAjustes extends StatefulWidget {
  const _FormularioAjustes({required this.perfil});

  final Perfil perfil;

  @override
  State<_FormularioAjustes> createState() => _FormularioAjustesState();
}

class _FormularioAjustesState extends State<_FormularioAjustes> {
  final _form = GlobalKey<FormState>();
  late final _meta = TextEditingController(
    text: '${widget.perfil.metaCalorias}',
  );
  late final _peso = TextEditingController(
    text: _decimal(widget.perfil.pesoKg).replaceAll(',', '.'),
  );
  late final _proteina = TextEditingController(
    text: '${widget.perfil.metaProteina}',
  );
  late final _carbohidratos = TextEditingController(
    text: '${widget.perfil.metaCarbohidratos}',
  );
  late final _grasas = TextEditingController(
    text: '${widget.perfil.metaGrasas}',
  );

  @override
  void dispose() {
    for (final c in [_meta, _peso, _proteina, _carbohidratos, _grasas]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Peso en kg: obligatorio y mayor que 0.
  static String? _validarPesoCorporal(String? valor) {
    final error = validarPeso(valor);
    if (error != null) return error;
    return leerDecimal(valor!)! <= 0 ? 'Mayor que 0' : null;
  }

  /// Gramos enteros obligatorios, 0 o más.
  static String? _validarMetaGramos(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Obligatorio';
    final numero = int.tryParse(texto);
    if (numero == null) return 'Número entero';
    return numero < 0 ? 'No negativo' : null;
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.perfil.copyWith(
        metaCalorias: int.parse(_meta.text.trim()),
        pesoKg: leerDecimal(_peso.text),
        metaProteina: int.parse(_proteina.text.trim()),
        metaCarbohidratos: int.parse(_carbohidratos.text.trim()),
        metaGrasas: int.parse(_grasas.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget campo(
      String etiqueta,
      TextEditingController c,
      String clave,
      String sufijo,
      String? Function(String?) validador,
    ) => Expanded(
      child: TextFormField(
        key: Key(clave),
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: etiqueta, suffixText: sufijo),
        validator: validador,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Metas', style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Se guardan en tu perfil.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                campo(
                  'Meta diaria',
                  _meta,
                  'campo-meta',
                  'kcal',
                  validarEnteroPositivo,
                ),
                const SizedBox(width: 10),
                campo(
                  'Tu peso',
                  _peso,
                  'campo-peso-corporal',
                  'kg',
                  _validarPesoCorporal,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                campo(
                  'Proteína',
                  _proteina,
                  'campo-meta-proteina',
                  'g',
                  _validarMetaGramos,
                ),
                const SizedBox(width: 10),
                campo(
                  'Carbos',
                  _carbohidratos,
                  'campo-meta-carbohidratos',
                  'g',
                  _validarMetaGramos,
                ),
                const SizedBox(width: 10),
                campo(
                  'Grasas',
                  _grasas,
                  'campo-meta-grasas',
                  'g',
                  _validarMetaGramos,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('guardar-ajustes'),
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
