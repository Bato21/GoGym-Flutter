import 'package:intl/intl.dart';

/// Utilidades de fecha compartidas por todas las vistas. Trabajan con la hora
/// local del dispositivo. Requieren `initializeDateFormatting('es')` en main.

/// Iniciales de lunes a domingo, como en el mockup.
const inicialesSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// La fecha a medianoche. Sirve de clave para agrupar por día.
DateTime soloDia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

/// Índice del día con la semana empezando en lunes (0 = lunes … 6 = domingo).
int indiceDia(DateTime fecha) => fecha.weekday - 1;

/// La fecha movida [dias] días (puede ser negativo), a medianoche.
/// Usa el constructor y no Duration para no fallar en cambios de horario.
DateTime sumarDias(DateTime fecha, int dias) =>
    DateTime(fecha.year, fecha.month, fecha.day + dias);

/// Lunes a medianoche de la semana de la fecha.
DateTime inicioSemana(DateTime fecha) => sumarDias(fecha, -indiceDia(fecha));

/// Días completos entre dos fechas, ignorando la hora.
int diasEntre(DateTime desde, DateTime hasta) =>
    (soloDia(hasta).difference(soloDia(desde)).inHours / 24).round();

/// Intl devuelve "lunes"; la app muestra "Lunes".
String capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

/// "Lunes 31 de agosto".
String fechaLarga(DateTime fecha) =>
    capitalizar(DateFormat("EEEE d 'de' MMMM", 'es').format(fecha));

/// "Lunes", "Martes"…
String nombreDia(DateTime fecha) =>
    capitalizar(DateFormat('EEEE', 'es').format(fecha));

/// "Hoy", "Ayer", el día de la semana si fue hace menos de 7 días, o "12 sept".
String diaRelativo(DateTime fecha, DateTime hoy) {
  final dias = diasEntre(fecha, hoy);
  if (dias == 0) return 'Hoy';
  if (dias == 1) return 'Ayer';
  if (dias > 1 && dias < 7) return nombreDia(fecha);
  return DateFormat('d MMM', 'es').format(fecha);
}

/// "45 min", "3h 20" o "2h".
String formatearTiempo(Duration duracion) {
  final minutos = duracion.inSeconds < 0 ? 0 : (duracion.inSeconds / 60).round();
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? '${horas}h' : '${horas}h ${resto.toString().padLeft(2, '0')}';
}
