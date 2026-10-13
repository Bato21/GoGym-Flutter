/// Entero con punto de miles, como en Chile: 8240 -> "8.240".
String formatearMiles(num valor) {
  final entero = valor.round();
  final digitos = entero.abs().toString();
  final buffer = StringBuffer(entero < 0 ? '-' : '');
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}
