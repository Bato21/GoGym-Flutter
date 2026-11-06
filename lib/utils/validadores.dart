/// Validadores de los formularios (Registrar entrenamiento, Calorías).
/// Devuelven el mensaje de error o null si el valor es válido.
library;

/// Entero mayor que 0, como repeticiones o series.
String? validarEnteroPositivo(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Obligatorio';
  final numero = int.tryParse(texto);
  if (numero == null) return 'Número entero';
  if (numero <= 0) return 'Mayor que 0';
  return null;
}

/// Minutos entre 1 y 600 (10 horas).
String? validarMinutos(String? valor) {
  final error = validarEnteroPositivo(valor);
  if (error != null) return error;
  return int.parse(valor!.trim()) > 600 ? 'Máximo 600' : null;
}

/// Kilos con decimales (acepta coma). 0 vale para peso corporal.
String? validarPeso(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Obligatorio';
  final numero = leerDecimal(texto);
  if (numero == null) return 'Número';
  if (numero < 0) return 'No negativo';
  if (numero > 1000) return 'Máximo 1000';
  return null;
}

/// "22,5" o "22.5" → 22.5; null si no es un número.
double? leerDecimal(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Gramos opcionales (macros): vacío vale 0; si no, número no negativo.
String? validarGramos(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return null;
  final numero = leerDecimal(texto);
  if (numero == null) return 'Número';
  if (numero < 0) return 'No negativo';
  return null;
}
