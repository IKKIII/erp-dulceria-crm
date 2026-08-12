import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Convierte una excepción técnica en un mensaje amigable en español.
/// Úsalo en los `catch (e)` de las pantallas, en vez de mostrar `$e` crudo:
///
/// ```dart
/// catch (e) {
///   setState(() => _error = friendlyError(e));
/// }
/// ```
String friendlyError(Object e) {
  if (e is SocketException) {
    return 'No hay conexión a internet. Revisa tu red e intenta de nuevo.';
  }
  if (e is TimeoutException) {
    return 'La operación tardó demasiado. Revisa tu conexión e intenta de nuevo.';
  }
  if (e is AuthException) {
    return e.message;
  }
  if (e is PostgrestException) {
    // Errores comunes de Postgres con mensaje más claro para el usuario.
    switch (e.code) {
      case '23505':
        return 'Ya existe un registro con ese mismo dato.';
      case '23503':
        return 'No se puede completar: hay otros datos que dependen de este registro.';
      case 'PGRST116':
        return 'No se encontró el registro solicitado.';
      default:
        return e.message;
    }
  }
  final texto = e.toString();
  if (texto.contains('SocketException') || texto.contains('Failed host lookup')) {
    return 'No hay conexión a internet. Revisa tu red e intenta de nuevo.';
  }
  return 'Ocurrió un problema inesperado. Intenta de nuevo en unos momentos.';
}
