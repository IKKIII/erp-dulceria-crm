import 'package:flutter/material.dart';
import '../theme.dart';

/// Diálogo emergente de aviso con ícono y color según el tipo de mensaje.
Future<void> mostrarAviso(
  BuildContext context, {
  required IconData icono,
  required Color color,
  required String titulo,
  required String mensaje,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Aviso rojo de error.
Future<void> mostrarAvisoError(
  BuildContext context, {
  String titulo = 'Ocurrió un error',
  required String mensaje,
}) {
  return mostrarAviso(
    context,
    icono: Icons.error_outline,
    color: kRed,
    titulo: titulo,
    mensaje: mensaje,
  );
}

/// Aviso naranja de información faltante o incompleta.
Future<void> mostrarAvisoFaltante(
  BuildContext context, {
  String titulo = 'Falta información',
  required String mensaje,
}) {
  return mostrarAviso(
    context,
    icono: Icons.info_outline,
    color: kOrange,
    titulo: titulo,
    mensaje: mensaje,
  );
}

/// SnackBar verde flotante de éxito.
SnackBar snackExito(String mensaje) {
  return SnackBar(
    backgroundColor: kGreen,
    behavior: SnackBarBehavior.floating,
    content: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(mensaje, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
