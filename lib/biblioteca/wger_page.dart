import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/wger_api.dart';
import '../models/ejercicio_wger.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/ejercicio_wger_card.dart';
import 'wger_detalle_page.dart';

/// Ejercicios traídos desde la API REST de wger con un GET, mostrados con
/// FutureBuilder y sus tres estados: cargando, error (con reintento) y datos.
class WgerPage extends StatefulWidget {
  const WgerPage({super.key});

  @override
  State<WgerPage> createState() => _WgerPageState();
}

class _WgerPageState extends State<WgerPage>
    with AutomaticKeepAliveClientMixin {
  /// Se guarda el Future: si se creara en build, cada reconstrucción (p. ej.
  /// al tocar un chip) repetiría la llamada a la API.
  late Future<List<EjercicioWger>> _ejercicios;
  String _categoria = 'Todas';

  @override
  void initState() {
    super.initState();
    _ejercicios = context.read<WgerApi>().ejercicios();
  }

  void _reintentar() => setState(() {
    _ejercicios = context.read<WgerApi>().ejercicios();
  });

  // Al cambiar de sub-pestaña no se descarta, así no vuelve a pedir la lista.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categoriasWger.length + 1,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final categoria = i == 0 ? 'Todas' : categoriasWger[i - 1];
              return ChipFiltro(
                texto: categoria,
                seleccionado: categoria == _categoria,
                onTap: () => setState(() => _categoria = categoria),
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<EjercicioWger>>(
            future: _ejercicios,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Error(onReintentar: _reintentar);
              }
              final ejercicios = snapshot.requireData
                  .where(
                    (e) => _categoria == 'Todas' || e.categoria == _categoria,
                  )
                  .toList();
              if (ejercicios.isEmpty) {
                return const Center(
                  child: Text('Sin ejercicios en esta categoría.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: ejercicios.length + 1,
                itemBuilder: (context, i) {
                  if (i == ejercicios.length) return const _Fuente();
                  final ejercicio = ejercicios[i];
                  return EjercicioWgerCard(
                    ejercicio: ejercicio,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WgerDetallePage(ejercicio: ejercicio),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: tema.colorScheme.error),
            const SizedBox(height: 12),
            const Text(
              'No pudimos conectar con wger. Revisa tu conexión.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('reintentar-wger'),
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atribución que pide la licencia de los datos de wger.
class _Fuente extends StatelessWidget {
  const _Fuente();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Datos de wger.de (CC-BY-SA 4.0)',
        textAlign: TextAlign.center,
        style: tema.textTheme.bodySmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
