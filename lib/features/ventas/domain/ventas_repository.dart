abstract class VentasRepository {
  Future<List<Map<String, dynamic>>> listar();
  Future<List<Map<String, dynamic>>> obtenerDetalle(int ventaId);
  Future<List<Map<String, dynamic>>> catalogoClientes();
  Future<List<Map<String, dynamic>>> catalogoProductosConStock();
  Future<void> registrarVenta({int? clienteId, required List<Map<String, dynamic>> items});
}
