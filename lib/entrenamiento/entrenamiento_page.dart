import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../biblioteca/biblioteca_page.dart';
import '../biblioteca/wger_page.dart';
import '../providers/entrenamientos_provider.dart';
import '../providers/perfil_provider.dart';
import '../widgets/sesion_card.dart';
import 'registrar_entrenamiento_page.dart';

/// Pestaña Entrenamiento: el historial (crear, editar y borrar sesiones), la
/// biblioteca de ejercicios (catálogo de Supabase) y los ejercicios de la API
/// de wger.
class EntrenamientoPage extends StatelessWidget {
  const EntrenamientoPage({super.key, this.ahora = DateTime.now});

  /// Reloj inyectable para las pruebas.
  final DateTime Function() ahora;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrenamiento'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Biblioteca'),
              Tab(text: 'wger'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Historial(ahora: ahora),
            const BibliotecaPage(),
            const WgerPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('nuevo-entrenamiento'),
          onPressed: () => abrirRegistro(context, ahora: ahora),
          icon: const Icon(Icons.add),
          label: const Text('Registrar'),
        ),
      ),
    );
  }
}

/// Entrenamientos terminados, el más reciente primero. Tocar uno lo abre para
/// editar; deslizarlo a la izquierda lo borra (con confirmación).
class _Historial extends StatelessWidget {
  const _Historial({required this.ahora});

  final DateTime Function() ahora;

  Future<void> _borrar(BuildContext context, int sesionId) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await context.read<EntrenamientosProvider>().borrar(sesionId);
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
    final historial = context.watch<EntrenamientosProvider>().historial;
    final pesoKg = context.watch<PerfilProvider>().perfil?.pesoKg;
    final hoy = ahora();
    final tema = Theme.of(context);

    if (historial.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aún no registras entrenamientos.\n'
            'Toca «Registrar» para anotar el primero.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      // Espacio abajo para que el botón flotante no tape la última sesión.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: historial.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final sesion = historial[i];
        return Dismissible(
          key: ValueKey('sesion-${sesion.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => confirmarBorrado(context),
          onDismissed: (_) => _borrar(context, sesion.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: tema.colorScheme.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.delete_outline, color: tema.colorScheme.onError),
          ),
          child: SesionCard.desde(
            sesion,
            hoy: hoy,
            pesoKg: pesoKg,
            onTap: () =>
                abrirRegistro(context, existente: sesion, ahora: ahora),
          ),
        );
      },
    );
  }
}
