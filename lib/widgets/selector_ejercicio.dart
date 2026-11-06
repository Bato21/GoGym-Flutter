import 'package:flutter/material.dart';

import '../models/ejercicio_catalogo.dart';
import 'ejercicio_card.dart';

/// Abre el catálogo en una hoja inferior con buscador y devuelve el ejercicio
/// tocado (null si se cierra). Lo usan Registrar entrenamiento y Calorías.
Future<EjercicioCatalogo?> elegirEjercicio(
  BuildContext context,
  Future<List<EjercicioCatalogo>> catalogo,
) => showModalBottomSheet<EjercicioCatalogo>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SelectorEjercicio(catalogo: catalogo),
);

/// Hoja inferior con el catálogo y un buscador. Devuelve el ejercicio tocado.
class _SelectorEjercicio extends StatefulWidget {
  const _SelectorEjercicio({required this.catalogo});

  final Future<List<EjercicioCatalogo>> catalogo;

  @override
  State<_SelectorEjercicio> createState() => _SelectorEjercicioState();
}

class _SelectorEjercicioState extends State<_SelectorEjercicio> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('buscar-en-selector'),
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Buscar ejercicio',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (texto) =>
                    setState(() => _busqueda = texto.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EjercicioCatalogo>>(
                future: widget.catalogo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('No se pudo cargar el catálogo.'),
                    );
                  }
                  final ejercicios = snapshot.requireData
                      .where(
                        (e) =>
                            _busqueda.isEmpty ||
                            e.nombre.toLowerCase().contains(_busqueda) ||
                            e.grupo.toLowerCase().contains(_busqueda),
                      )
                      .toList();
                  if (ejercicios.isEmpty) {
                    return const Center(child: Text('Sin resultados.'));
                  }
                  return ListView.builder(
                    itemCount: ejercicios.length,
                    itemBuilder: (context, i) => EjercicioCard(
                      ejercicio: ejercicios[i],
                      onTap: () => Navigator.of(context).pop(ejercicios[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
