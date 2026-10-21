import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/entrenamientos_provider.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/tarjeta.dart';

/// Resumen de logros. Todos los avances se calculan desde las sesiones reales.
class LogrosPage extends StatelessWidget {
  const LogrosPage({super.key, this.ahora = DateTime.now});

  final DateTime Function() ahora;

  @override
  Widget build(BuildContext context) {
    final entrenamientos = context.watch<EntrenamientosProvider>();
    final hoy = ahora();
    final total = entrenamientos.historial.length;
    final semana = entrenamientos.deLaSemana(hoy).length;
    final racha = entrenamientos.rachaActual(hoy);
    final record = entrenamientos.rachaRecord;
    final logros = <_Logro>[
      _Logro(
        titulo: 'Primer entrenamiento',
        descripcion: 'Completa tu primer entrenamiento',
        icono: Icons.fitness_center,
        actual: total,
        meta: 1,
      ),
      _Logro(
        titulo: 'En llamas',
        descripcion: 'Entrena 3 días seguidos',
        icono: Icons.local_fire_department_outlined,
        actual: record,
        meta: 3,
      ),
      _Logro(
        titulo: 'Semana perfecta',
        descripcion: 'Completa 3 entrenamientos esta semana',
        icono: Icons.calendar_month_outlined,
        actual: semana,
        meta: 3,
      ),
      _Logro(
        titulo: 'Constancia',
        descripcion: 'Completa 10 entrenamientos',
        icono: Icons.trending_up,
        actual: total,
        meta: 10,
      ),
      _Logro(
        titulo: 'Atleta',
        descripcion: 'Completa 25 entrenamientos',
        icono: Icons.military_tech_outlined,
        actual: total,
        meta: 25,
      ),
      _Logro(
        titulo: 'Leyenda',
        descripcion: 'Completa 100 entrenamientos',
        icono: Icons.workspace_premium_outlined,
        actual: total,
        meta: 100,
      ),
    ];
    final desbloqueados = logros.where((logro) => logro.completado).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: entrenamientos.recargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _ResumenLogros(
                desbloqueados: desbloqueados,
                total: logros.length,
                racha: racha,
                record: record,
              ),
              const SizedBox(height: 22),
              Text(
                'TUS LOGROS',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < logros.length; i++) ...[
                _LogroCard(logro: logros[i]),
                if (i != logros.length - 1) const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenLogros extends StatelessWidget {
  const _ResumenLogros({
    required this.desbloqueados,
    required this.total,
    required this.racha,
    required this.record,
  });

  final int desbloqueados;
  final int total;
  final int racha;
  final int record;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final avance = total == 0 ? 0.0 : desbloqueados / total;

    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colores.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: colores.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mis logros',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$desbloqueados de $total desbloqueados',
            style: tema.textTheme.bodySmall?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: avance),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => LinearProgressIndicator(
                value: valor,
                minHeight: 6,
                backgroundColor: colores.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 15,
                color: racha > 0 ? Colors.amber : colores.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$racha ${racha == 1 ? 'día' : 'días'} de racha',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: '  ·  Récord $record',
                        style: TextStyle(color: colores.onSurfaceVariant),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(avance * 100).round()}%',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: colores.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Logro {
  const _Logro({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.actual,
    required this.meta,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final int actual;
  final int meta;

  bool get completado => actual >= meta;
  int get progreso => math.min(actual, meta);
}

class _LogroCard extends StatelessWidget {
  const _LogroCard({required this.logro});

  final _Logro logro;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final activo = logro.completado;

    return PressableScale(
      child: Tarjeta(
        onTap: () => _mostrarDetalle(context, logro),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo
                    ? colores.primary.withValues(alpha: 0.15)
                    : colores.onSurface.withValues(alpha: 0.04),
              ),
              child: Icon(
                activo ? logro.icono : Icons.lock_outline,
                size: 21,
                color: activo ? colores.primary : colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logro.titulo,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: activo ? null : colores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    logro.descripcion,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: colores.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (activo)
              Icon(Icons.check_rounded, color: colores.primary, size: 23)
            else
              Text(
                '${logro.progreso}/${logro.meta}',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: colores.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _mostrarDetalle(BuildContext context, _Logro logro) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar detalle del logro',
    barrierColor: Colors.black.withValues(alpha: .62),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _LogroPopup(logro: logro),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final entrada = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .82, end: 1.0).animate(entrada),
          child: child,
        ),
      );
    },
  );
}

class _LogroPopup extends StatelessWidget {
  const _LogroPopup({required this.logro});

  final _Logro logro;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final activo = logro.completado;
    final avance = logro.meta == 0 ? 0.0 : logro.progreso / logro.meta;
    final mensaje = activo
        ? '¡${logro.titulo} desbloqueado!'
        : 'Te faltan ${logro.meta - logro.progreso} para desbloquear ${logro.titulo}.';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colores.primary.withValues(alpha: .14),
                  boxShadow: [
                    BoxShadow(
                      color: colores.primary.withValues(alpha: .2),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  activo ? logro.icono : Icons.lock_outline_rounded,
                  color: activo ? colores.primary : colores.onSurfaceVariant,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                activo ? 'LOGRO DESBLOQUEADO' : 'SIGUE AVANZANDO',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: colores.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                logro.titulo,
                textAlign: TextAlign.center,
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: colores.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (!activo) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: avance),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, child) => LinearProgressIndicator(
                      value: valor,
                      minHeight: 7,
                      backgroundColor: colores.primary.withValues(alpha: .15),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${logro.progreso} de ${logro.meta}',
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: colores.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PressableScale(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('cerrar-logro'),
                    onPressed: () => Navigator.pop(context),
                    child: Text(activo ? '¡GENIAL!' : 'SEGUIR ENTRENANDO'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
