import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/perfil.dart';
import '../models/rutina.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/rutinas_provider.dart';
import '../utils/fechas.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/tarjeta.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key, this.ahora = DateTime.now});

  final DateTime Function() ahora;

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>().perfil;
    final rutinasProvider = context.watch<RutinasProvider>();
    final entrenamientos = context.watch<EntrenamientosProvider>();
    if (perfil == null) {
      return const Scaffold(
        appBar: _PerfilAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hoy = ahora();
    final rutinas = rutinasProvider.disponibles;
    final proximos = _proximosEntrenamientos(
      perfil: perfil,
      rutinas: rutinas,
      siguiente: rutinasProvider.siguiente(entrenamientos.historial),
      hoy: hoy,
    );
    final semana = entrenamientos.deLaSemana(hoy).length;
    final metaSemana = perfil.diasEntrenamiento.isEmpty
        ? 3
        : perfil.diasEntrenamiento.length;
    final rutinaFavorita = _rutinaFavorita(perfil, rutinas);

    return Scaffold(
      appBar: const _PerfilAppBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            context.read<PerfilProvider>().recargar(),
            context.read<RutinasProvider>().recargar(),
            context.read<EntrenamientosProvider>().recargar(),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _CabeceraPerfil(
                perfil: perfil,
                racha: entrenamientos.rachaActual(hoy),
              ),
              const SizedBox(height: 22),
              const _TituloSeccion(
                icono: Icons.calendar_month_outlined,
                texto: 'Próximos entrenamientos',
              ),
              const SizedBox(height: 10),
              if (proximos.isEmpty)
                const _EstadoVacio(
                  texto:
                      'Define tus días y crea una rutina para ver tu agenda.',
                )
              else
                for (var i = 0; i < proximos.length; i++) ...[
                  _EntrenamientoProgramado(item: proximos[i]),
                  if (i != proximos.length - 1) const SizedBox(height: 9),
                ],
              const SizedBox(height: 22),
              const _TituloSeccion(
                icono: Icons.favorite_border,
                texto: 'Mi progreso',
              ),
              const SizedBox(height: 10),
              _DatoPerfil(
                icono: Icons.emoji_events_outlined,
                etiqueta: 'Mi objetivo',
                valor: perfil.objetivo.trim().isEmpty
                    ? 'Sin definir'
                    : perfil.objetivo.trim(),
              ),
              const SizedBox(height: 9),
              _DatoPerfil(
                icono: Icons.monitor_weight_outlined,
                etiqueta: 'Peso corporal',
                valor: '${_peso(perfil.pesoKg)} kg',
              ),
              const SizedBox(height: 9),
              _ProgresoSemana(actual: semana, meta: metaSemana),
              const SizedBox(height: 9),
              _DatoPerfil(
                icono: Icons.star_border_rounded,
                etiqueta: 'Rutina favorita',
                valor: rutinaFavorita?.nombre ?? 'Sin elegir',
              ),
              const SizedBox(height: 18),
              PressableScale(
                pressedScale: 0.985,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('editar-perfil'),
                    onPressed: () => _editarPerfil(context, perfil, rutinas),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('EDITAR PERFIL'),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _peso(double valor) => valor == valor.roundToDouble()
      ? valor.toInt().toString()
      : valor.toStringAsFixed(1);

  static Rutina? _rutinaFavorita(Perfil perfil, List<Rutina> rutinas) {
    for (final rutina in rutinas) {
      if (rutina.id == perfil.rutinaFavoritaId) return rutina;
    }
    return null;
  }

  static List<_ProximoEntrenamiento> _proximosEntrenamientos({
    required Perfil perfil,
    required List<Rutina> rutinas,
    required Rutina? siguiente,
    required DateTime hoy,
  }) {
    if (perfil.diasEntrenamiento.isEmpty || rutinas.isEmpty) return const [];
    var indiceRutina = siguiente == null ? 0 : rutinas.indexOf(siguiente);
    if (indiceRutina < 0) indiceRutina = 0;
    final resultado = <_ProximoEntrenamiento>[];
    for (var dias = 0; dias < 28 && resultado.length < 3; dias++) {
      final fecha = sumarDias(hoy, dias);
      if (!perfil.esDiaEntrenamiento(fecha)) continue;
      resultado.add(
        _ProximoEntrenamiento(
          rutina: rutinas[indiceRutina % rutinas.length],
          fecha: fecha,
          hora: perfil.horaEntrenamiento,
          esHoy: dias == 0,
        ),
      );
      indiceRutina++;
    }
    return resultado;
  }

  static Future<void> _editarPerfil(
    BuildContext context,
    Perfil perfil,
    List<Rutina> rutinas,
  ) async {
    final editado = await showDialog<Perfil>(
      context: context,
      builder: (_) => _EditorPerfil(perfil: perfil, rutinas: rutinas),
    );
    if (editado == null || !context.mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    try {
      await context.read<PerfilProvider>().actualizar(editado);
      if (!context.mounted) return;
      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Perfil actualizado'),
          ),
        );
    } catch (_) {
      if (!context.mounted) return;
      mensajero.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No se pudo guardar. Revisa tu conexión.'),
        ),
      );
    }
  }
}

class _PerfilAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PerfilAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Perfil'));
}

class _CabeceraPerfil extends StatelessWidget {
  const _CabeceraPerfil({required this.perfil, required this.racha});

  final Perfil perfil;
  final int racha;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final nombre = '${perfil.nombre.trim()} ${perfil.apellido.trim()}'.trim();
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colores.primary.withValues(alpha: 0.1),
              border: Border.all(color: colores.primary, width: 3),
            ),
            child: perfil.iniciales.isEmpty
                ? Icon(Icons.person, color: colores.primary, size: 31)
                : Text(
                    perfil.iniciales,
                    style: tema.textTheme.titleMedium?.copyWith(
                      color: colores.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            nombre.isEmpty ? 'Mi perfil' : nombre,
            textAlign: TextAlign.center,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mi perfil de entrenamiento',
            style: tema.textTheme.bodySmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colores.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: racha > 0 ? Colors.amber : colores.primary,
                  size: 19,
                ),
                const SizedBox(width: 6),
                Text(
                  '$racha ${racha == 1 ? 'día' : 'días'} de racha',
                  style: tema.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(icono, color: tema.colorScheme.primary, size: 19),
        const SizedBox(width: 7),
        Text(
          texto,
          style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProximoEntrenamiento {
  const _ProximoEntrenamiento({
    required this.rutina,
    required this.fecha,
    required this.hora,
    required this.esHoy,
  });

  final Rutina rutina;
  final DateTime fecha;
  final String hora;
  final bool esHoy;
}

class _EntrenamientoProgramado extends StatelessWidget {
  const _EntrenamientoProgramado({required this.item});

  final _ProximoEntrenamiento item;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final fecha = item.esHoy
        ? 'Hoy'
        : capitalizar(DateFormat('EEEE d', 'es').format(item.fecha));
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _IconoDato(icono: Icons.calendar_month_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.rutina.nombre,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  fecha,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.schedule, size: 14, color: colores.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            item.hora.isEmpty ? '--:--' : item.hora,
            style: tema.textTheme.labelSmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  const _DatoPerfil({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _IconoDato(icono: icono),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  valor,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconoDato extends StatelessWidget {
  const _IconoDato({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icono, color: color, size: 20),
    );
  }
}

class _ProgresoSemana extends StatelessWidget {
  const _ProgresoSemana({required this.actual, required this.meta});

  final int actual;
  final int meta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final avance = meta == 0 ? 0.0 : math.min(1.0, actual / meta);
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrenamientos esta semana',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$actual de $meta',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.fitness_center, size: 18, color: colores.primary),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: avance),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, valor, child) => LinearProgressIndicator(
                value: valor,
                minHeight: 5,
                backgroundColor: colores.primary.withValues(alpha: .18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Tarjeta(
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _EditorPerfil extends StatefulWidget {
  const _EditorPerfil({required this.perfil, required this.rutinas});

  final Perfil perfil;
  final List<Rutina> rutinas;

  @override
  State<_EditorPerfil> createState() => _EditorPerfilState();
}

class _EditorPerfilState extends State<_EditorPerfil> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _objetivo;
  late final TextEditingController _peso;
  late final TextEditingController _hora;
  late Set<int> _dias;
  int? _rutinaId;

  static const _diasCortos = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final perfil = widget.perfil;
    _nombre = TextEditingController(text: perfil.nombre);
    _apellido = TextEditingController(text: perfil.apellido);
    _objetivo = TextEditingController(text: perfil.objetivo);
    _peso = TextEditingController(text: PerfilPage._peso(perfil.pesoKg));
    _hora = TextEditingController(text: perfil.horaEntrenamiento);
    _dias = perfil.diasEntrenamiento.toSet();
    _rutinaId = widget.rutinas.any((r) => r.id == perfil.rutinaFavoritaId)
        ? perfil.rutinaFavoritaId
        : null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _objetivo.dispose();
    _peso.dispose();
    _hora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, limites) {
                    final campos = [
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Escribe tu nombre'
                            : null,
                      ),
                      TextFormField(
                        controller: _apellido,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                        ),
                      ),
                    ];
                    if (limites.maxWidth < 420) {
                      return Column(children: [campos[0], campos[1]]);
                    }
                    return Row(
                      children: [
                        Expanded(child: campos[0]),
                        const SizedBox(width: 12),
                        Expanded(child: campos[1]),
                      ],
                    );
                  },
                ),
                TextFormField(
                  key: const Key('campo-objetivo'),
                  controller: _objetivo,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo',
                    hintText: 'Ej. Ganar masa muscular',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _peso,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso',
                          suffixText: 'kg',
                        ),
                        validator: _validarPeso,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hora,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          hintText: '18:00',
                        ),
                        validator: _validarHora,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Días de entrenamiento',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  children: [
                    for (var i = 0; i < 7; i++)
                      FilterChip(
                        label: Text(_diasCortos[i]),
                        selected: _dias.contains(i),
                        onSelected: (seleccionado) => setState(() {
                          if (seleccionado) {
                            _dias.add(i);
                          } else {
                            _dias.remove(i);
                          }
                        }),
                      ),
                  ],
                ),
                if (widget.rutinas.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int?>(
                    initialValue: _rutinaId,
                    decoration: const InputDecoration(
                      labelText: 'Rutina favorita',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin elegir'),
                      ),
                      for (final rutina in widget.rutinas)
                        DropdownMenuItem<int?>(
                          value: rutina.id,
                          child: Text(rutina.nombre),
                        ),
                    ],
                    onChanged: (valor) => _rutinaId = valor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        PressableScale(
          child: FilledButton(
            key: const Key('guardar-perfil'),
            onPressed: _guardar,
            child: const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  String? _validarPeso(String? valor) {
    final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
    if (numero == null || numero <= 0 || numero > 500) {
      return 'Peso inválido';
    }
    return null;
  }

  String? _validarHora(String? valor) {
    final partes = (valor ?? '').split(':');
    if (partes.length != 2) return 'Usa HH:mm';
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null || hora > 23 || minuto > 59) {
      return 'Hora inválida';
    }
    return null;
  }

  void _guardar() {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final dias = _dias.toList()..sort();
    Navigator.pop(
      context,
      widget.perfil.copyWith(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        objetivo: _objetivo.text.trim(),
        pesoKg: double.parse(_peso.text.replaceAll(',', '.')),
        horaEntrenamiento: _hora.text.trim(),
        diasEntrenamiento: dias,
        rutinaFavoritaId: _rutinaId,
        quitarRutinaFavorita: _rutinaId == null,
      ),
    );
  }
}
