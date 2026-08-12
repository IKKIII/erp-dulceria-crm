import 'package:flutter/services.dart';

/// Genera un CSV a partir de encabezados + filas y lo copia al
/// portapapeles (Clipboard) — así el usuario lo pega directo en Excel,
/// Google Sheets, o un archivo de texto. No usa ningún paquete nativo
/// adicional (a diferencia de compartir un archivo), así que no depende
/// de la versión de Android SDK del proyecto.
Future<void> exportarCsv({
  required String nombreArchivo,
  required List<String> encabezados,
  required List<List<dynamic>> filas,
}) async {
  final buffer = StringBuffer();
  buffer.writeln(encabezados.map(_escaparCsv).join(','));
  for (final fila in filas) {
    buffer.writeln(fila.map(_escaparCsv).join(','));
  }
  await Clipboard.setData(ClipboardData(text: buffer.toString()));
}

String _escaparCsv(dynamic valor) {
  final texto = (valor ?? '').toString();
  if (texto.contains(',') || texto.contains('"') || texto.contains('\n')) {
    return '"${texto.replaceAll('"', '""')}"';
  }
  return texto;
}
