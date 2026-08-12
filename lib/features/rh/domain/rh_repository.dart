import 'usuario.dart';

abstract class RhRepository {
  Future<List<Usuario>> listarUsuarios();
  Future<void> actualizarRol(String userId, String nuevoRol);

  /// Cuántas ventas emitió cada vendedor (requiere la migración 2:
  /// columna vendedor_id en ventas).
  Future<List<Map<String, dynamic>>> ventasPorVendedor();
}
